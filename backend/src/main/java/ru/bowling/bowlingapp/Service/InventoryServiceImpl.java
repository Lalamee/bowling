package ru.bowling.bowlingapp.Service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.InventoryItemRequest;
import ru.bowling.bowlingapp.DTO.InventorySearchRequest;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.WarehouseMovementDto;
import ru.bowling.bowlingapp.DTO.WarehouseSummaryDto;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.EquipmentCategory;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;
import ru.bowling.bowlingapp.Entity.ManagerProfile;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.PersonalWarehouse;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.PersonalWarehouseRepository;
import ru.bowling.bowlingapp.Repository.PartImageRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.EquipmentCategoryRepository;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;
import ru.bowling.bowlingapp.Repository.projection.WarehouseAggregateProjection;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class InventoryServiceImpl implements InventoryService {

    private static final int LOW_STOCK_THRESHOLD = 3;
    private static final Logger log = LoggerFactory.getLogger(InventoryServiceImpl.class);

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private PartImageRepository partImageRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private PersonalWarehouseRepository personalWarehouseRepository;

    @Autowired
    private EquipmentComponentRepository equipmentComponentRepository;

    @Autowired
    private EquipmentCategoryRepository equipmentCategoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<PartDto> searchParts(InventorySearchRequest request) {
        String normalizedQuery = request != null && request.getQuery() != null ? request.getQuery().trim() : "";
        Integer warehouseIdFilter = resolveWarehouseId(request);
        InventoryAvailabilityFilter availabilityFilter = request != null ? request.getAvailability() : null;
        String normalizedCategoryCode = normalizeCategoryCode(request != null ? request.getCategoryCode() : null);
        String componentCategoryCode = resolveComponentCategory(request != null ? request.getComponentId() : null);
        final String categoryCodeFilter = componentCategoryCode != null ? componentCategoryCode : normalizedCategoryCode;
        Set<Integer> allowedWarehouses = normalizeAllowedWarehouses(
                request != null ? request.getAllowedWarehouseIds() : null);

        if (normalizedQuery.isEmpty()) {
            List<WarehouseInventory> inventories = warehouseIdFilter != null
                    ? warehouseInventoryRepository.findByWarehouseId(warehouseIdFilter)
                    : warehouseInventoryRepository.findAll();

            if (inventories.isEmpty()) {
                return Collections.emptyList();
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
                    .filter(inv -> matchesWarehouse(inv, warehouseIdFilter, allowedWarehouses))
                    .filter(inv -> matchesAvailability(inv, availabilityFilter))
                    .map(inv -> {
                        Long catalogId = inv.getCatalogId() != null ? inv.getCatalogId().longValue() : null;
                        PartsCatalog catalog = catalogId != null ? catalogById.get(catalogId) : null;
                        return convertToDto(catalog, inv);
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
        }

        List<PartsCatalog> parts = partsCatalogRepository.searchByNameOrNumberOrDescription(normalizedQuery);
        if (categoryCodeFilter != null) {
            parts = parts.stream()
                    .filter(part -> {
                        String normalizedPartCode = normalizeCategoryCode(part.getCategoryCode());
                        return normalizedPartCode != null && normalizedPartCode.startsWith(categoryCodeFilter);
                    })
                    .collect(Collectors.toList());
        }
        if (parts.isEmpty()) {
            return Collections.emptyList();
        }
        List<PartDto> results = new ArrayList<>();
        for (PartsCatalog part : parts) {
            List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
            for (WarehouseInventory inventory : inventories) {
                if (!matchesWarehouse(inventory, warehouseIdFilter, allowedWarehouses)) {
                    continue;
                }
                if (!matchesAvailability(inventory, availabilityFilter)) {
                    continue;
                }
                PartDto dto = convertToDto(part, inventory);
                if (dto != null) {
                    results.add(dto);
                }
            }
        }
        return results;
    }

    @Override
    @Transactional(readOnly = true)
    public PartDto getPartById(Long partId) {
        WarehouseInventory inventory = warehouseInventoryRepository.findById(partId)
                .orElseThrow(() -> new RuntimeException("Part inventory not found"));
        Integer catalogId = inventory.getCatalogId();
        if (catalogId == null) {
            throw new RuntimeException("Inventory item is not linked to a catalog entry");
        }
        PartsCatalog part = partsCatalogRepository.findById(Long.valueOf(catalogId))
                .orElseThrow(() -> new RuntimeException("Part not found"));
        PartDto dto = convertToDto(part, inventory);
        if (dto == null) {
            EquipmentCategory category = resolveCategory(part);
            List<Long> categoryPath = buildCategoryPath(category);
            return PartDto.builder()
                    .inventoryId(inventory.getInventoryId())
                    .catalogId(part.getCatalogId())
                    .catalogNumber(part.getCatalogNumber())
                    .officialNameEn(part.getOfficialNameEn())
                    .officialNameRu(part.getOfficialNameRu())
                    .commonName(part.getCommonName())
                    .description(part.getDescription())
                    .quantity(inventory.getQuantity())
                    .reservedQuantity(inventory.getReservedQuantity())
                    .warehouseId(inventory.getWarehouseId())
                    .location(inventory.getLocationReference())
                    .cellCode(inventory.getCellCode())
                    .shelfCode(inventory.getShelfCode())
                    .laneNumber(inventory.getLaneNumber())
                    .placementStatus(Optional.ofNullable(inventory.getPlacementStatus())
                            .orElseGet(() -> resolvePlacementStatus(inventory)))
                    .unique(Boolean.TRUE.equals(inventory.getIsUnique()))
                    .lastChecked(inventory.getLastChecked())
                    .notes(inventory.getNotes())
                    .imageUrl(resolveImageUrl(part))
                    .diagramUrl(null)
                    .equipmentNodeId(category != null ? category.getId() : null)
                    .equipmentNodePath(categoryPath)
                    .equipmentNodeName(category != null ? resolveCategoryName(category) : null)
                    .compatibility(Collections.emptyList())
                    .build();
        }
        return dto;
    }

    @Override
    public void reservePart(ReservationRequestDto reservationRequestDto) {
        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(reservationRequestDto.getPartId().intValue());
        if (inventories.isEmpty()) {
            throw new RuntimeException("Part inventory not found");
        }

        WarehouseInventory inventory = inventories.get(0); // Take first available inventory
        if (inventory.getQuantity() < reservationRequestDto.getQuantity()) {
            throw new RuntimeException("Not enough parts in stock");
        }

        inventory.setQuantity(inventory.getQuantity() - reservationRequestDto.getQuantity());
        warehouseInventoryRepository.save(inventory);
        log.info("Reserved {} units of catalog {} (inventory id {}) in warehouse {} by request {}",
                reservationRequestDto.getQuantity(), inventory.getCatalogId(), inventory.getInventoryId(),
                inventory.getWarehouseId(), reservationRequestDto.getMaintenanceRequestId());
    }

    @Override
    public void releasePart(ReservationRequestDto reservationRequestDto) {
        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(reservationRequestDto.getPartId().intValue());
        if (inventories.isEmpty()) {
            throw new RuntimeException("Part inventory not found");
        }

        WarehouseInventory inventory = inventories.get(0); // Take first available inventory
        inventory.setQuantity(inventory.getQuantity() + reservationRequestDto.getQuantity());
        warehouseInventoryRepository.save(inventory);
        log.info("Released {} units of catalog {} (inventory id {}) back to warehouse {} for request {}",
                reservationRequestDto.getQuantity(), inventory.getCatalogId(), inventory.getInventoryId(),
                inventory.getWarehouseId(), reservationRequestDto.getMaintenanceRequestId());
    }

    @Override
    @Transactional
    public List<WarehouseSummaryDto> getAccessibleWarehouses(Long userId) {
        if (userId == null) {
            return Collections.emptyList();
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Set<Integer> warehouseIds = new HashSet<>();
        Map<Integer, WarehouseType> typeByWarehouse = new HashMap<>();
        Map<Integer, PersonalWarehouse> personalWarehouseById = new HashMap<>();

        if (user.getManagerProfile() != null && user.getManagerProfile().getClub() != null) {
            BowlingClub managerClub = user.getManagerProfile().getClub();
            boolean approvedManager = Boolean.TRUE.equals(user.getManagerProfile().getIsDataVerified())
                    && clubStaffRepository.existsByClubAndUserAndIsActiveTrue(managerClub, user);
            if (approvedManager) {
                Integer clubWarehouseId = managerClub.getClubId() != null
                        ? managerClub.getClubId().intValue()
                        : null;
                if (clubWarehouseId != null) {
                    warehouseIds.add(clubWarehouseId);
                    typeByWarehouse.put(clubWarehouseId, WarehouseType.CLUB);
                }
            }
        }

        if (user.getMechanicProfile() != null && user.getMechanicProfile().getClubs() != null) {
            for (BowlingClub club : user.getMechanicProfile().getClubs()) {
                if (club == null || club.getClubId() == null) {
                    continue;
                }
                if (!hasActiveStaffAccess(user, club)) {
                    continue;
                }
                Integer warehouseId = club.getClubId().intValue();
                warehouseIds.add(warehouseId);
                typeByWarehouse.put(warehouseId, WarehouseType.CLUB);
            }
        }

        if (user.getMechanicProfile() != null && user.getMechanicProfile().getProfileId() != null) {
            List<PersonalWarehouse> personalWarehouses = personalWarehouseRepository
                    .findByMechanicProfile_ProfileIdAndIsActiveTrue(user.getMechanicProfile().getProfileId());

            if (personalWarehouses.isEmpty()) {
                PersonalWarehouse created = ensurePersonalWarehouse(user.getMechanicProfile());
                personalWarehouses = List.of(created);
            }

            for (PersonalWarehouse warehouse : personalWarehouses) {
                if (warehouse == null || warehouse.getWarehouseId() == null) {
                    continue;
                }
                Integer warehouseId = warehouse.getWarehouseId();
                warehouseIds.add(warehouseId);
                typeByWarehouse.put(warehouseId, WarehouseType.PERSONAL);
                personalWarehouseById.put(warehouseId, warehouse);
            }
        }

        if (user.getOwnerProfile() != null && user.getOwnerProfile().getClubs() != null) {
            for (BowlingClub club : user.getOwnerProfile().getClubs()) {
                if (club == null || club.getClubId() == null) {
                    continue;
                }
                Integer warehouseId = club.getClubId().intValue();
                warehouseIds.add(warehouseId);
                typeByWarehouse.putIfAbsent(warehouseId, WarehouseType.CLUB);
            }
        }

        if (warehouseIds.isEmpty()) {
            return Collections.emptyList();
        }

        Map<Integer, WarehouseAggregateProjection> aggregateByWarehouse = warehouseInventoryRepository
                .aggregateByWarehouseIds(warehouseIds, LOW_STOCK_THRESHOLD)
                .stream()
                .collect(Collectors.toMap(WarehouseAggregateProjection::getWarehouseId, Function.identity()));

        Map<Long, BowlingClub> clubsById = bowlingClubRepository.findAllById(
                        warehouseIds.stream().map(Integer::longValue).collect(Collectors.toSet()))
                .stream()
                .collect(Collectors.toMap(BowlingClub::getClubId, Function.identity()));

        List<WarehouseSummaryDto> result = new ArrayList<>();
        for (Integer warehouseId : warehouseIds) {
            BowlingClub club = clubsById.get(warehouseId.longValue());
            WarehouseAggregateProjection projection = aggregateByWarehouse.get(warehouseId);
            WarehouseType warehouseType = typeByWarehouse.getOrDefault(warehouseId, WarehouseType.CLUB);
            PersonalWarehouse personalWarehouse = personalWarehouseById.get(warehouseId);
            Long clubId = club != null ? club.getClubId() : null;
            String displayName = club != null ? club.getName() : null;
            if (warehouseType == WarehouseType.PERSONAL) {
                clubId = null;
                displayName = personalWarehouse != null && personalWarehouse.getName() != null
                        ? personalWarehouse.getName()
                        : "Личный склад";
            }
            result.add(WarehouseSummaryDto.builder()
                    .warehouseId(warehouseId)
                    .clubId(clubId)
                    .clubName(displayName != null ? displayName : "Личный склад")
                    .warehouseType(warehouseType)
                    .totalPositions(projection != null && projection.getTotalItems() != null
                            ? projection.getTotalItems().intValue()
                            : null)
                    .lowStockPositions(projection != null && projection.getLowItems() != null
                            ? projection.getLowItems().intValue()
                            : null)
                    .reservedPositions(projection != null && projection.getReservedItems() != null
                            ? projection.getReservedItems().intValue()
                            : null)
                    .personalAccess(warehouseType == WarehouseType.PERSONAL)
                    .build());
        }
        return result;
    }

    private boolean hasActiveStaffAccess(User user, BowlingClub club) {
        if (user == null || club == null || club.getClubId() == null || user.getUserId() == null) {
            return false;
        }
        return clubStaffRepository.existsByClubClubIdAndUserUserIdAndIsActiveTrue(club.getClubId(), user.getUserId());
    }

    @Override
    @Transactional(readOnly = true)
    public List<WarehouseMovementDto> getWarehouseMovements(Integer warehouseId) {
        if (warehouseId == null) {
            return Collections.emptyList();
        }

        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByWarehouseId(warehouseId);
        if (inventories.isEmpty()) {
            return Collections.emptyList();
        }

        LocalDateTime now = LocalDateTime.now();
        return inventories.stream()
                .map(inv -> WarehouseMovementDto.builder()
                        .warehouseId(inv.getWarehouseId())
                        .catalogId(inv.getCatalogId())
                        .inventoryId(inv.getInventoryId())
                        .quantityDelta(inv.getQuantity())
                        .operationType("SNAPSHOT")
                        .comment("Текущее количество по позиции склада")
                        .occurredAt(Optional.ofNullable(inv.getLastChecked())
                                .map(date -> date.atStartOfDay())
                                .orElse(now))
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public PartDto addInventoryItem(Long userId, InventoryItemRequest request) {
        if (userId == null) {
            throw new IllegalArgumentException("Пользователь обязателен для добавления на склад");
        }
        if (request == null) {
            throw new IllegalArgumentException("Данные о позиции склада не переданы");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        WarehouseTarget target = resolveWarehouseTarget(user, request);

        PartsCatalog part = partsCatalogRepository.findById(request.getCatalogId())
                .orElseThrow(() -> new IllegalArgumentException("Каталожная позиция не найдена"));

        WarehouseInventory inventory = warehouseInventoryRepository
                .findFirstByWarehouseIdAndCatalogId(target.warehouseId, part.getCatalogId().intValue());

        int quantityToAdd = Optional.ofNullable(request.getQuantity()).orElse(0);
        int reservedToAdd = Optional.ofNullable(request.getReservedQuantity()).orElse(0);

        if (inventory == null) {
            inventory = WarehouseInventory.builder()
                    .warehouseId(target.warehouseId)
                    .catalogId(part.getCatalogId().intValue())
                    .quantity(quantityToAdd)
                    .reservedQuantity(reservedToAdd)
                    .locationReference(request.getLocationReference())
                    .cellCode(request.getCellCode())
                    .shelfCode(request.getShelfCode())
                    .laneNumber(request.getLaneNumber())
                    .placementStatus(request.getPlacementStatus())
                    .notes(request.getNotes())
                    .isUnique(request.getIsUnique())
                    .build();
        } else {
            inventory.setQuantity(Optional.ofNullable(inventory.getQuantity()).orElse(0) + quantityToAdd);
            inventory.setReservedQuantity(Optional.ofNullable(inventory.getReservedQuantity()).orElse(0) + reservedToAdd);
            if (request.getLocationReference() != null) {
                inventory.setLocationReference(request.getLocationReference());
            }
            if (request.getCellCode() != null) {
                inventory.setCellCode(request.getCellCode());
            }
            if (request.getShelfCode() != null) {
                inventory.setShelfCode(request.getShelfCode());
            }
            if (request.getLaneNumber() != null) {
                inventory.setLaneNumber(request.getLaneNumber());
            }
            if (request.getPlacementStatus() != null) {
                inventory.setPlacementStatus(request.getPlacementStatus());
            }
            if (request.getNotes() != null) {
                inventory.setNotes(request.getNotes());
            }
            if (request.getIsUnique() != null) {
                inventory.setIsUnique(request.getIsUnique());
            }
        }

        WarehouseInventory saved = warehouseInventoryRepository.save(inventory);
        return convertToDto(part, saved);
    }

    private WarehouseTarget resolveWarehouseTarget(User user, InventoryItemRequest request) {
        Integer requestedWarehouseId = request.getWarehouseId();
        Long requestedClubId = request.getClubId();

        if (requestedWarehouseId != null) {
            Optional<PersonalWarehouse> personal = personalWarehouseRepository.findById(requestedWarehouseId);
            if (personal.isPresent()) {
                requirePersonalAccess(user, personal.get());
                return WarehouseTarget.personal(requestedWarehouseId);
            }
            BowlingClub club = bowlingClubRepository.findById(requestedWarehouseId.longValue())
                    .orElseThrow(() -> new IllegalArgumentException("Клубный склад не найден"));
            requireClubManagementAccess(user, club);
            return WarehouseTarget.club(requestedWarehouseId, club);
        }

        if (requestedClubId != null) {
            BowlingClub club = bowlingClubRepository.findById(requestedClubId)
                    .orElseThrow(() -> new IllegalArgumentException("Клуб не найден"));
            requireClubManagementAccess(user, club);
            return WarehouseTarget.club(Math.toIntExact(club.getClubId()), club);
        }

        if (user.getMechanicProfile() != null) {
            PersonalWarehouse personalWarehouse = ensurePersonalWarehouse(user.getMechanicProfile());
            return WarehouseTarget.personal(personalWarehouse.getWarehouseId());
        }

        throw new IllegalStateException("Не удалось определить доступный склад для добавления позиции");
    }

    private void requirePersonalAccess(User user, PersonalWarehouse warehouse) {
        if (user == null || warehouse == null || warehouse.getMechanicProfile() == null
                || user.getMechanicProfile() == null) {
            throw new IllegalArgumentException("Личный склад доступен только владельцу-механику");
        }
        if (!Objects.equals(warehouse.getMechanicProfile().getProfileId(), user.getMechanicProfile().getProfileId())) {
            throw new IllegalArgumentException("Вы не можете добавлять позиции в чужой личный склад");
        }
    }

    private void requireClubManagementAccess(User user, BowlingClub club) {
        if (club == null) {
            throw new IllegalArgumentException("Клуб не найден");
        }
        if (isAdministrator(user)) {
            return;
        }
        if (isOwnerOfClub(user, club)) {
            return;
        }
        if (isManagerOfClub(user, club)) {
            return;
        }
        throw new IllegalArgumentException("Добавлять позиции могут только менеджер или владелец клуба");
    }

    private boolean isOwnerOfClub(User user, BowlingClub club) {
        OwnerProfile ownerProfile = user != null ? user.getOwnerProfile() : null;
        if (ownerProfile == null || club == null || club.getClubId() == null) {
            return false;
        }
        return Optional.ofNullable(ownerProfile.getClubs())
                .orElseGet(ArrayList::new)
                .stream()
                .filter(Objects::nonNull)
                .anyMatch(c -> Objects.equals(c.getClubId(), club.getClubId()));
    }

    private boolean isManagerOfClub(User user, BowlingClub club) {
        ManagerProfile managerProfile = user != null ? user.getManagerProfile() : null;
        if (managerProfile == null || club == null || club.getClubId() == null) {
            return false;
        }
        if (!Boolean.TRUE.equals(managerProfile.getIsDataVerified())) {
            return false;
        }
        return managerProfile.getClub() != null && Objects.equals(managerProfile.getClub().getClubId(), club.getClubId());
    }

    private boolean isAdministrator(User user) {
        if (user == null || user.getRole() == null || user.getRole().getName() == null) {
            return false;
        }
        return user.getRole().getName().toUpperCase(Locale.ROOT).contains("ADMIN");
    }

        private PersonalWarehouse ensurePersonalWarehouse(MechanicProfile mechanicProfile) {
                List<PersonalWarehouse> warehouses = personalWarehouseRepository
                        .findByMechanicProfile_ProfileIdAndIsActiveTrue(mechanicProfile.getProfileId());
                if (!warehouses.isEmpty()) {
                        return warehouses.get(0);
                }
                PersonalWarehouse created = PersonalWarehouse.builder()
                        .mechanicProfile(mechanicProfile)
                        .name("Личный zip-склад " + Optional.ofNullable(mechanicProfile.getFullName())
                                .orElse("механика"))
                        .isActive(true)
                        .createdAt(LocalDateTime.now())
                        .updatedAt(LocalDateTime.now())
                        .build();
        return personalWarehouseRepository.save(created);
    }

    private record WarehouseTarget(Integer warehouseId, BowlingClub club, boolean personal) {
        private static WarehouseTarget personal(Integer warehouseId) {
            return new WarehouseTarget(warehouseId, null, true);
        }

        private static WarehouseTarget club(Integer warehouseId, BowlingClub club) {
            return new WarehouseTarget(warehouseId, club, false);
        }
    }

    private PartDto convertToDto(PartsCatalog part, WarehouseInventory inventory) {
        if (part == null || inventory == null) {
            return null;
        }
        Integer quantity = inventory.getQuantity();
        if (quantity == null) {
            quantity = 0;
        }
        EquipmentCategory category = resolveCategory(part);
        List<Long> categoryPath = buildCategoryPath(category);

        return PartDto.builder()
                .inventoryId(inventory.getInventoryId())
                .catalogId(part.getCatalogId())
                .officialNameEn(part.getOfficialNameEn())
                .officialNameRu(part.getOfficialNameRu())
                .commonName(part.getCommonName())
                .description(part.getDescription())
                .catalogNumber(part.getCatalogNumber())
                .quantity(quantity)
                .reservedQuantity(inventory.getReservedQuantity())
                .location(inventory.getLocationReference())
                .cellCode(inventory.getCellCode())
                .shelfCode(inventory.getShelfCode())
                .laneNumber(inventory.getLaneNumber())
                .placementStatus(Optional.ofNullable(inventory.getPlacementStatus())
                        .orElseGet(() -> resolvePlacementStatus(inventory)))
                .warehouseId(inventory.getWarehouseId())
                .unique(Boolean.TRUE.equals(inventory.getIsUnique()))
                .lastChecked(inventory.getLastChecked())
                .notes(inventory.getNotes())
                .imageUrl(resolveImageUrl(part))
                .diagramUrl(null)
                .equipmentNodeId(category != null ? category.getId() : null)
                .equipmentNodePath(categoryPath)
                .equipmentNodeName(category != null ? resolveCategoryName(category) : null)
                .compatibility(Collections.emptyList())
                .build();
    }

    private String resolveImageUrl(PartsCatalog part) {
        if (part == null || part.getCatalogId() == null) {
            return null;
        }
        return partImageRepository.findFirstByCatalogId(part.getCatalogId()).map(image -> image.getImageUrl()).orElse(null);
    }

    private EquipmentCategory resolveCategory(PartsCatalog part) {
        if (part == null) {
            return null;
        }
        String code = part.getCategoryCode();
        if (code == null || code.isBlank()) {
            return null;
        }
        String trimmed = code.trim();
        try {
            Long id = Long.parseLong(trimmed);
            return equipmentCategoryRepository.findByIdAndIsActiveTrue(id).orElse(null);
        } catch (NumberFormatException ignored) {
            return equipmentCategoryRepository.findByCodeIgnoreCaseAndIsActiveTrue(trimmed).orElse(null);
        }
    }

    private List<Long> buildCategoryPath(EquipmentCategory category) {
        if (category == null) {
            return Collections.emptyList();
        }
        List<Long> path = new ArrayList<>();
        EquipmentCategory current = category;
        while (current != null) {
            if (current.getId() != null) {
                path.add(current.getId());
            }
            current = current.getParent();
        }
        Collections.reverse(path);
        return path;
    }

    private String resolveCategoryName(EquipmentCategory category) {
        if (category == null) {
            return null;
        }
        if (category.getNameRu() != null && !category.getNameRu().isBlank()) {
            return category.getNameRu().trim();
        }
        if (category.getNameEn() != null && !category.getNameEn().isBlank()) {
            return category.getNameEn().trim();
        }
        return null;
    }

    private boolean matchesWarehouse(WarehouseInventory inventory,
                                     Integer warehouseIdFilter,
                                     Set<Integer> allowedWarehouses) {
        if (warehouseIdFilter != null && !Objects.equals(warehouseIdFilter, inventory.getWarehouseId())) {
            return false;
        }
        if (allowedWarehouses != null) {
            Integer warehouseId = inventory.getWarehouseId();
            if (warehouseId == null || !allowedWarehouses.contains(warehouseId)) {
                return false;
            }
        }
        return true;
    }

    private boolean matchesAvailability(WarehouseInventory inventory, InventoryAvailabilityFilter filter) {
        if (filter == null || filter == InventoryAvailabilityFilter.ALL) {
            return true;
        }
        Integer qty = inventory.getQuantity();
        if (qty == null) {
            qty = 0;
        }
        if (filter == InventoryAvailabilityFilter.IN_STOCK) {
            return qty > 0;
        }
        if (filter == InventoryAvailabilityFilter.LOW_STOCK) {
            return qty <= LOW_STOCK_THRESHOLD;
        }
        return true;
    }

    private Integer resolveWarehouseId(InventorySearchRequest request) {
        if (request == null) {
            return null;
        }
        if (request.getWarehouseId() != null) {
            return request.getWarehouseId();
        }
        if (request.getClubId() != null) {
            return request.getClubId().intValue();
        }
        return null;
    }

    private Set<Integer> normalizeAllowedWarehouses(Set<Integer> allowedWarehouseIds) {
        if (allowedWarehouseIds == null) {
            return null;
        }
        return allowedWarehouseIds.stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private String resolvePlacementStatus(WarehouseInventory inventory) {
        if (inventory.getLaneNumber() != null) {
            return "ON_LANE";
        }
        if (inventory.getLocationReference() != null && !inventory.getLocationReference().isBlank()) {
            return "IN_WAREHOUSE";
        }
        if ((inventory.getCellCode() != null && !inventory.getCellCode().isBlank())
                || (inventory.getShelfCode() != null && !inventory.getShelfCode().isBlank())) {
            return "IN_WAREHOUSE";
        }
        return null;
    }

    private String normalizeCategoryCode(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return trimmed.toUpperCase(Locale.ROOT);
    }

    private String resolveComponentCategory(Long componentId) {
        if (componentId == null) {
            return null;
        }
        EquipmentComponent component = equipmentComponentRepository.findById(componentId)
                .orElse(null);
        if (component == null || component.getCode() == null || component.getCode().isBlank()) {
            return null;
        }
        return normalizeCategoryCode(component.getCode());
    }
}
