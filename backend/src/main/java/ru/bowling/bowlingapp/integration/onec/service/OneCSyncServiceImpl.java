package ru.bowling.bowlingapp.integration.onec.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;
import ru.bowling.bowlingapp.integration.onec.client.OneCClient;
import ru.bowling.bowlingapp.integration.onec.config.OneCIntegrationProperties;
import ru.bowling.bowlingapp.integration.onec.dto.OneCProductDto;
import ru.bowling.bowlingapp.integration.onec.dto.OneCStockItemDto;
import ru.bowling.bowlingapp.integration.onec.dto.OneCSyncStatusDto;
import ru.bowling.bowlingapp.integration.onec.exception.OneCSyncException;
import ru.bowling.bowlingapp.integration.onec.mapper.OneCInventoryMapper;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class OneCSyncServiceImpl implements OneCSyncService {

    private static final Logger log = LoggerFactory.getLogger(OneCSyncServiceImpl.class);

    private final OneCClient oneCClient;
    private final PartsCatalogRepository partsCatalogRepository;
    private final WarehouseInventoryRepository warehouseInventoryRepository;
    private final OneCInventoryMapper mapper;
    private final OneCIntegrationProperties properties;

    private volatile OneCSyncStatusDto lastStatus = OneCSyncStatusDto.builder()
            .success(false)
            .message("Синхронизация еще не запускалась")
            .trigger("SYSTEM")
            .imported(0)
            .updated(0)
            .skipped(0)
            .build();

    public OneCSyncServiceImpl(OneCClient oneCClient,
                               PartsCatalogRepository partsCatalogRepository,
                               WarehouseInventoryRepository warehouseInventoryRepository,
                               OneCInventoryMapper mapper,
                               OneCIntegrationProperties properties) {
        this.oneCClient = oneCClient;
        this.partsCatalogRepository = partsCatalogRepository;
        this.warehouseInventoryRepository = warehouseInventoryRepository;
        this.mapper = mapper;
        this.properties = properties;
    }

    @Override
    @Transactional
    public OneCSyncStatusDto runManualSync() {
        return sync("MANUAL");
    }

    @Scheduled(cron = "${integration.onec.sync-cron:0 */30 * * * *}")
    @Transactional
    public void runScheduledSync() {
        if (!properties.isEnabled()) {
            return;
        }
        sync("SCHEDULED");
    }

    @Override
    public OneCSyncStatusDto getLastStatus() {
        return lastStatus;
    }

    private OneCSyncStatusDto sync(String trigger) {
        if (!properties.isEnabled()) {
            lastStatus = OneCSyncStatusDto.builder()
                    .startedAt(LocalDateTime.now())
                    .finishedAt(LocalDateTime.now())
                    .success(false)
                    .trigger(trigger)
                    .message("Интеграция 1С отключена (integration.onec.enabled=false)")
                    .imported(0)
                    .updated(0)
                    .skipped(0)
                    .build();
            return lastStatus;
        }

        LocalDateTime startedAt = LocalDateTime.now();
        int imported = 0;
        int updated = 0;
        int skipped = 0;

        try {
            exportProductsWithRetry();
            List<OneCStockItemDto> items = importStockBalancesWithRetry();

            for (OneCStockItemDto item : items) {
                if (item == null || item.getCatalogNumber() == null || item.getWarehouseId() == null) {
                    skipped++;
                    continue;
                }
                Optional<PartsCatalog> partOpt = partsCatalogRepository.findByCatalogNumber(item.getCatalogNumber());
                if (partOpt.isEmpty()) {
                    skipped++;
                    continue;
                }
                Integer catalogId = Math.toIntExact(partOpt.get().getCatalogId());
                WarehouseInventory existing = warehouseInventoryRepository
                        .findFirstByWarehouseIdAndCatalogId(item.getWarehouseId(), catalogId);
                boolean wasExisting = existing != null;
                WarehouseInventory mapped = mapper.toWarehouseInventory(catalogId, item, existing);
                warehouseInventoryRepository.save(mapped);
                if (wasExisting) {
                    updated++;
                } else {
                    imported++;
                }
            }

            lastStatus = OneCSyncStatusDto.builder()
                    .startedAt(startedAt)
                    .finishedAt(LocalDateTime.now())
                    .success(true)
                    .trigger(trigger)
                    .message("Синхронизация 1С успешно завершена")
                    .imported(imported)
                    .updated(updated)
                    .skipped(skipped)
                    .build();
            return lastStatus;
        } catch (Exception ex) {
            log.error("1C sync failed", ex);
            lastStatus = OneCSyncStatusDto.builder()
                    .startedAt(startedAt)
                    .finishedAt(LocalDateTime.now())
                    .success(false)
                    .trigger(trigger)
                    .message(ex.getMessage())
                    .imported(imported)
                    .updated(updated)
                    .skipped(skipped)
                    .build();
            throw new OneCSyncException("Ошибка синхронизации с 1С", ex);
        }
    }

    private List<OneCStockItemDto> importStockBalancesWithRetry() {
        return executeWithRetry(oneCClient::importStockBalances, "import stock balances");
    }

    private void exportProductsWithRetry() {
        List<OneCProductDto> payload = partsCatalogRepository.findAll().stream()
                .map(this::toProductDto)
                .toList();
        executeWithRetry(() -> {
            oneCClient.exportProducts(payload);
            return null;
        }, "export products");
    }

    private OneCProductDto toProductDto(PartsCatalog part) {
        return OneCProductDto.builder()
                .catalogNumber(part.getCatalogNumber())
                .nameRu(part.getOfficialNameRu())
                .nameEn(part.getOfficialNameEn())
                .description(part.getDescription())
                .build();
    }

    private <T> T executeWithRetry(java.util.concurrent.Callable<T> action, String actionName) {
        int attempts = Math.max(1, properties.getRetryAttempts() != null ? properties.getRetryAttempts() : 1);
        long delayMs = Math.max(0L, properties.getRetryDelayMs() != null ? properties.getRetryDelayMs() : 0L);
        Exception last = null;

        for (int attempt = 1; attempt <= attempts; attempt++) {
            try {
                return action.call();
            } catch (Exception ex) {
                last = ex;
                log.warn("1C {} failed on attempt {}/{}: {}", actionName, attempt, attempts, ex.getMessage());
                if (attempt < attempts && delayMs > 0) {
                    try {
                        Thread.sleep(delayMs * attempt);
                    } catch (InterruptedException interruptedException) {
                        Thread.currentThread().interrupt();
                        throw new IllegalStateException("Retry interrupted", interruptedException);
                    }
                }
            }
        }
        throw new IllegalStateException("1C action failed after retries: " + actionName, last);
    }
}
