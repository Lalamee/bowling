package ru.bowling.bowlingapp.Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.InventorySearchRequest;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.WarehouseSummaryDto;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;
import ru.bowling.bowlingapp.Repository.projection.WarehouseAggregateProjection;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class InventoryServiceImpl implements InventoryService {

    private static final int LOW_STOCK_THRESHOLD = 3;

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Override
    @Transactional(readOnly = true)
    public List<PartDto> searchParts(InventorySearchRequest request) {
        String normalizedQuery = request != null && request.getQuery() != null ? request.getQuery().trim() : "";
        Integer warehouseIdFilter = resolveWarehouseId(request);
        InventoryAvailabilityFilter availabilityFilter = request != null ? request.getAvailability() : null;

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
                    .filter(inv -> matchesWarehouse(inv, warehouseIdFilter))
                    .filter(inv -> matchesAvailability(inv, availabilityFilter))
                    .map(inv -> {
                        Long catalogId = inv.getCatalogId() != null ? inv.getCatalogId().longValue() : null;
                        PartsCatalog catalog = catalogId != null ? catalogById.get(catalogId) : null;
                        return convertToDto(catalog, inv);
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
        }

        List<PartsCatalog> parts = partsCatalogRepository.searchByNameOrNumber(normalizedQuery);
        if (parts.isEmpty()) {
            return Collections.emptyList();
        }
        // TODO: добавить фильтр по categoryCode, когда поле появится в PartsCatalog

        List<PartDto> results = new ArrayList<>();
        for (PartsCatalog part : parts) {
            List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
            for (WarehouseInventory inventory : inventories) {
                if (!matchesWarehouse(inventory, warehouseIdFilter)) {
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
        // TODO: Add transaction logging
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
        // TODO: Add transaction logging
    }

    @Override
    @Transactional(readOnly = true)
    public List<WarehouseSummaryDto> getAccessibleWarehouses(Long userId) {
        if (userId == null) {
            return Collections.emptyList();
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Set<Integer> warehouseIds = new HashSet<>();
        Map<Integer, WarehouseType> typeByWarehouse = new HashMap<>();

        if (user.getManagerProfile() != null && user.getManagerProfile().getClub() != null) {
            Integer clubWarehouseId = user.getManagerProfile().getClub().getClubId() != null
                    ? user.getManagerProfile().getClub().getClubId().intValue()
                    : null;
            if (clubWarehouseId != null) {
                warehouseIds.add(clubWarehouseId);
                typeByWarehouse.put(clubWarehouseId, WarehouseType.CLUB);
            }
        }

        if (user.getMechanicProfile() != null && user.getMechanicProfile().getClubs() != null) {
            for (BowlingClub club : user.getMechanicProfile().getClubs()) {
                if (club == null || club.getClubId() == null) {
                    continue;
                }
                Integer warehouseId = club.getClubId().intValue();
                warehouseIds.add(warehouseId);
                typeByWarehouse.put(warehouseId, WarehouseType.CLUB);
            }
        }

        // TODO: добавить персональные склады механиков, когда появится отдельная таблица personal_warehouses

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
            result.add(WarehouseSummaryDto.builder()
                    .warehouseId(warehouseId)
                    .clubId(club != null ? club.getClubId() : warehouseId.longValue())
                    .clubName(club != null ? club.getName() : "Личный склад")
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

    private PartDto convertToDto(PartsCatalog part, WarehouseInventory inventory) {
        if (part == null || inventory == null) {
            return null;
        }
        Integer quantity = inventory.getQuantity();
        if (quantity == null) {
            quantity = 0;
        }

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
                .build();
    }

    private boolean matchesWarehouse(WarehouseInventory inventory, Integer warehouseIdFilter) {
        return warehouseIdFilter == null || Objects.equals(warehouseIdFilter, inventory.getWarehouseId());
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

    private String resolvePlacementStatus(WarehouseInventory inventory) {
        if (inventory.getLaneNumber() != null) {
            return "ON_LANE"; // TODO: отдать человекочитаемый статус, когда появится DTO дорожек
        }
        if (inventory.getLocationReference() != null && !inventory.getLocationReference().isBlank()) {
            return "IN_WAREHOUSE";
        }
        return null;
    }
}
