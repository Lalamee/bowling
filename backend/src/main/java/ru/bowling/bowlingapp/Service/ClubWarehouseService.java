package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.WarehouseItemRequestDTO;
import ru.bowling.bowlingapp.DTO.WarehouseItemResponseDTO;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class ClubWarehouseService {

    private final WarehouseInventoryRepository warehouseInventoryRepository;
    private final PartsCatalogRepository partsCatalogRepository;
    private final BowlingClubRepository bowlingClubRepository;

    @Transactional
    public WarehouseItemResponseDTO upsertInventoryItem(Long clubId, WarehouseItemRequestDTO request) {
        if (clubId == null) {
            throw new IllegalArgumentException("Не указан клуб для пополнения склада");
        }
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Клуб с идентификатором " + clubId + " не найден"));

        if (request == null) {
            throw new IllegalArgumentException("Данные запчасти обязательны");
        }

        Integer warehouseId = resolveWarehouseId(club.getClubId());
        if (warehouseId == null) {
            throw new IllegalArgumentException("Не удалось определить склад для клуба " + clubId);
        }

        WarehouseInventory inventory = null;
        if (request.getInventoryId() != null) {
            inventory = warehouseInventoryRepository.findById(request.getInventoryId())
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Позиция склада с идентификатором " + request.getInventoryId() + " не найдена"));
            if (inventory.getWarehouseId() != null && !Objects.equals(inventory.getWarehouseId(), warehouseId)) {
                throw new IllegalArgumentException("Выбранная позиция склада относится к другому клубу");
            }
        }

        PartsCatalog catalog = resolveOrCreateCatalog(request);
        if (catalog == null || catalog.getCatalogId() == null) {
            throw new IllegalArgumentException("Не удалось определить каталог для запчасти");
        }

        Integer catalogIdInt = toCatalogIdInt(catalog.getCatalogId());
        if (catalogIdInt == null) {
            throw new IllegalArgumentException("Каталог запчастей имеет некорректный идентификатор");
        }

        if (inventory == null) {
            inventory = warehouseInventoryRepository.findByWarehouseIdAndCatalogId(warehouseId, catalogIdInt)
                    .orElseGet(() -> WarehouseInventory.builder()
                            .warehouseId(warehouseId)
                            .catalogId(catalogIdInt)
                            .quantity(0)
                            .build());
        } else {
            inventory.setCatalogId(catalogIdInt);
        }

        Integer quantityChange = request.getQuantity();
        boolean replaceQuantity = Boolean.TRUE.equals(request.getReplaceQuantity());

        if (inventory.getInventoryId() == null && (quantityChange == null || quantityChange <= 0)) {
            throw new IllegalArgumentException("Количество для новой позиции склада должно быть больше нуля");
        }

        if (quantityChange != null) {
            if (replaceQuantity) {
                if (quantityChange < 0) {
                    throw new IllegalArgumentException("Количество не может быть отрицательным");
                }
                inventory.setQuantity(quantityChange);
            } else {
                if (quantityChange < 0) {
                    throw new IllegalArgumentException("Нельзя уменьшать количество через пополнение склада");
                }
                int baseQuantity = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
                long newQuantity = (long) baseQuantity + quantityChange;
                if (newQuantity > Integer.MAX_VALUE) {
                    throw new IllegalArgumentException("Слишком большое количество для хранения на складе");
                }
                inventory.setQuantity((int) newQuantity);
            }
        } else if (inventory.getQuantity() == null) {
            inventory.setQuantity(0);
        }

        if (request.getLocation() != null) {
            inventory.setLocationReference(normalizeValue(request.getLocation()));
        }
        if (request.getNotes() != null) {
            inventory.setNotes(normalizeValue(request.getNotes()));
        }

        if (request.getUnique() != null) {
            inventory.setIsUnique(request.getUnique());
        } else if (inventory.getInventoryId() == null) {
            inventory.setIsUnique(catalog.getIsUnique());
        }

        if (inventory.getLastChecked() == null || replaceQuantity || quantityChange != null) {
            inventory.setLastChecked(LocalDate.now());
        }

        WarehouseInventory savedInventory = warehouseInventoryRepository.save(inventory);

        return toResponse(club.getClubId(), savedInventory, catalog);
    }

    @Transactional(readOnly = true)
    public List<WarehouseItemResponseDTO> getWarehouseItems(Long clubId) {
        if (clubId == null) {
            return List.of();
        }
        Integer warehouseId = resolveWarehouseId(clubId);
        if (warehouseId == null) {
            return List.of();
        }

        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByWarehouseId(warehouseId);
        if (inventories.isEmpty()) {
            return List.of();
        }

        Set<Long> catalogIds = inventories.stream()
                .map(WarehouseInventory::getCatalogId)
                .filter(Objects::nonNull)
                .map(Integer::longValue)
                .collect(Collectors.toSet());

        Map<Long, PartsCatalog> catalogById = catalogIds.isEmpty()
                ? Collections.emptyMap()
                : partsCatalogRepository.findAllById(catalogIds).stream()
                        .collect(Collectors.toMap(PartsCatalog::getCatalogId, Function.identity()));

        return inventories.stream()
                .map(inventory -> {
                    PartsCatalog catalog = inventory.getCatalogId() != null
                            ? catalogById.get(Long.valueOf(inventory.getCatalogId()))
                            : null;
                    return toResponse(clubId, inventory, catalog);
                })
                .collect(Collectors.toList());
    }

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

    private WarehouseItemResponseDTO toResponse(Long clubId, WarehouseInventory inventory, PartsCatalog catalog) {
        if (inventory == null) {
            return null;
        }

        return WarehouseItemResponseDTO.builder()
                .clubId(clubId)
                .inventoryId(inventory.getInventoryId())
                .warehouseId(inventory.getWarehouseId())
                .catalogId(catalog != null ? catalog.getCatalogId() : null)
                .catalogNumber(catalog != null ? catalog.getCatalogNumber() : null)
                .officialNameRu(catalog != null ? catalog.getOfficialNameRu() : null)
                .officialNameEn(catalog != null ? catalog.getOfficialNameEn() : null)
                .commonName(catalog != null ? catalog.getCommonName() : null)
                .description(catalog != null ? catalog.getDescription() : null)
                .quantity(inventory.getQuantity())
                .unique(inventory.getIsUnique())
                .location(inventory.getLocationReference())
                .notes(inventory.getNotes())
                .lastChecked(inventory.getLastChecked())
                .build();
    }

    private PartsCatalog resolveOrCreateCatalog(WarehouseItemRequestDTO request) {
        if (request == null) {
            return null;
        }

        Long requestCatalogId = request.getCatalogId();
        PartsCatalog catalog = null;
        if (requestCatalogId != null) {
            catalog = partsCatalogRepository.findById(requestCatalogId)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Каталог с идентификатором " + requestCatalogId + " не найден"));
        }

        String catalogNumber = normalizeValue(request.getCatalogNumber());
        String nameRu = normalizeValue(request.getOfficialNameRu());
        String nameEn = normalizeValue(request.getOfficialNameEn());
        String commonName = normalizeValue(request.getCommonName());
        String description = normalizeValue(request.getDescription());

        if (catalog == null && catalogNumber != null) {
            catalog = partsCatalogRepository.findByCatalogNumber(catalogNumber).orElse(null);
        }

        if (catalog == null) {
            String lookupName = nameRu != null ? nameRu : (commonName != null ? commonName : nameEn);
            if (lookupName != null) {
                List<PartsCatalog> candidates = partsCatalogRepository.findByAnyNameIgnoreCase(lookupName);
                if (!candidates.isEmpty()) {
                    catalog = candidates.get(0);
                }
            }
        }

        if (catalog == null) {
            if (catalogNumber == null && nameRu == null && commonName == null && nameEn == null) {
                throw new IllegalArgumentException("Необходимо указать хотя бы название или каталожный номер запчасти");
            }
            PartsCatalog newCatalog = PartsCatalog.builder()
                    .catalogNumber(catalogNumber)
                    .officialNameRu(nameRu != null ? nameRu : commonName)
                    .officialNameEn(nameEn)
                    .commonName(commonName)
                    .description(description)
                    .isUnique(request.getUnique())
                    .build();
            return partsCatalogRepository.save(newCatalog);
        }

        boolean updated = false;
        if (catalogNumber != null && !Objects.equals(catalog.getCatalogNumber(), catalogNumber)) {
            catalog.setCatalogNumber(catalogNumber);
            updated = true;
        }
        if (nameRu != null && !Objects.equals(catalog.getOfficialNameRu(), nameRu)) {
            catalog.setOfficialNameRu(nameRu);
            updated = true;
        }
        if (nameEn != null && !Objects.equals(catalog.getOfficialNameEn(), nameEn)) {
            catalog.setOfficialNameEn(nameEn);
            updated = true;
        }
        if (commonName != null && !Objects.equals(catalog.getCommonName(), commonName)) {
            catalog.setCommonName(commonName);
            updated = true;
        }
        if (description != null && !Objects.equals(catalog.getDescription(), description)) {
            catalog.setDescription(description);
            updated = true;
        }
        if (request.getUnique() != null && !Objects.equals(catalog.getIsUnique(), request.getUnique())) {
            catalog.setIsUnique(request.getUnique());
            updated = true;
        }

        if (updated) {
            catalog = partsCatalogRepository.save(catalog);
        }

        return catalog;
    }

    private Integer toCatalogIdInt(Long catalogId) {
        if (catalogId == null) {
            return null;
        }
        try {
            return Math.toIntExact(catalogId);
        } catch (ArithmeticException ex) {
            log.warn("Catalog id {} exceeds supported inventory id range", catalogId, ex);
            return null;
        }
    }

    private String normalizeValue(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
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

