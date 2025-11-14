package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class ClubWarehouseService {

    private final WarehouseInventoryRepository warehouseInventoryRepository;
    private final PartsCatalogRepository partsCatalogRepository;
    private final BowlingClubRepository bowlingClubRepository;

    @Transactional
    public void initializeWarehouseForClub(BowlingClub club) {
        Map<Long, PartsCatalog> catalogById = loadCatalogById();
        initializeWarehouseForClub(club, catalogById);
    }

    private void initializeWarehouseForClub(BowlingClub club, Map<Long, PartsCatalog> catalogById) {
        if (club == null) {
            return;
        }

        Integer warehouseId = resolveWarehouseId(club.getClubId());
        if (warehouseId == null) {
            return;
        }

        List<WarehouseInventory> existingEntries = warehouseInventoryRepository.findByWarehouseId(warehouseId);
        Set<Integer> existingCatalogIds = existingEntries.stream()
                .map(WarehouseInventory::getCatalogId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        List<WarehouseInventory> inventoriesToCreate = catalogById.values().stream()
                .filter(part -> !existingCatalogIds.contains(part.getCatalogId().intValue()))
                .map(part -> WarehouseInventory.builder()
                        .warehouseId(warehouseId)
                        .catalogId(part.getCatalogId().intValue())
                        .quantity(0)
                        .lastChecked(LocalDate.now())
                        .isUnique(part.getIsUnique())
                        .build())
                .collect(Collectors.toList());

        if (!inventoriesToCreate.isEmpty()) {
            warehouseInventoryRepository.saveAll(inventoriesToCreate);
        }

        List<WarehouseInventory> inventoriesToUpdate = new ArrayList<>();
        for (WarehouseInventory inventory : existingEntries) {
            if (inventory.getCatalogId() == null) {
                continue;
            }
            PartsCatalog catalog = catalogById.get(Long.valueOf(inventory.getCatalogId()));
            if (catalog == null) {
                continue;
            }
            Boolean catalogUnique = catalog.getIsUnique();
            if (!Objects.equals(inventory.getIsUnique(), catalogUnique)) {
                inventory.setIsUnique(catalogUnique);
                inventoriesToUpdate.add(inventory);
            }
            if (inventory.getLastChecked() == null) {
                inventory.setLastChecked(LocalDate.now());
                if (!inventoriesToUpdate.contains(inventory)) {
                    inventoriesToUpdate.add(inventory);
                }
            }
        }

        if (!inventoriesToUpdate.isEmpty()) {
            warehouseInventoryRepository.saveAll(inventoriesToUpdate);
        }
    }

    @Transactional
    public void initializeWarehousesForClubs(Collection<BowlingClub> clubs) {
        if (clubs == null || clubs.isEmpty()) {
            return;
        }
        Map<Long, PartsCatalog> catalogById = loadCatalogById();
        for (BowlingClub club : clubs) {
            try {
                initializeWarehouseForClub(club, catalogById);
            } catch (Exception ex) {
                log.error("Failed to initialize warehouse for club {}", club != null ? club.getClubId() : null, ex);
            }
        }
    }

    @Transactional
    public void initializeAllClubWarehouses() {
        List<BowlingClub> clubs = bowlingClubRepository.findAll();
        initializeWarehousesForClubs(clubs);
    }

    @Transactional
    public void registerDelivery(BowlingClub club, Map<Integer, Integer> deliveredQuantities) {
        if (club == null || deliveredQuantities == null || deliveredQuantities.isEmpty()) {
            return;
        }

        Integer warehouseId = resolveWarehouseId(club.getClubId());
        if (warehouseId == null) {
            return;
        }

        deliveredQuantities.forEach((catalogId, quantity) -> {
            if (catalogId == null || quantity == null || quantity <= 0) {
                return;
            }

            WarehouseInventory inventory = warehouseInventoryRepository.findFirstByWarehouseIdAndCatalogId(warehouseId, catalogId);
            if (inventory == null) {
                inventory = WarehouseInventory.builder()
                        .warehouseId(warehouseId)
                        .catalogId(catalogId)
                        .quantity(quantity)
                        .lastChecked(LocalDate.now())
                        .build();
            } else {
                int current = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
                inventory.setQuantity(current + quantity);
                if (inventory.getLastChecked() == null) {
                    inventory.setLastChecked(LocalDate.now());
                }
            }
            warehouseInventoryRepository.save(inventory);
        });
    }

    private Map<Long, PartsCatalog> loadCatalogById() {
        return partsCatalogRepository.findAll().stream()
                .filter(part -> part.getCatalogId() != null)
                .collect(Collectors.toMap(PartsCatalog::getCatalogId, part -> part));
    }

    private Integer resolveWarehouseId(Long clubId) {
        if (clubId == null) {
            return null;
        }
        try {
            return Math.toIntExact(clubId);
        } catch (ArithmeticException ex) {
            log.warn("Club id {} exceeds supported warehouse id range", clubId, ex);
            return null;
        }
    }
}

