package ru.bowling.bowlingapp.Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class InventoryServiceImpl implements InventoryService {

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Override
    public List<PartDto> searchParts(String query, Long clubId) {
        String normalizedQuery = query != null ? query.trim() : "";
        Integer warehouseIdFilter = clubId != null ? clubId.intValue() : null;

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
                    .filter(inv -> warehouseIdFilter == null || Objects.equals(inv.getWarehouseId(), warehouseIdFilter))
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
            return java.util.Collections.emptyList();
        }

        List<PartDto> results = new ArrayList<>();
        for (PartsCatalog part : parts) {
            List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
            for (WarehouseInventory inventory : inventories) {
                if (warehouseIdFilter != null && !Objects.equals(warehouseIdFilter, inventory.getWarehouseId())) {
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
                    .warehouseId(inventory.getWarehouseId())
                    .location(inventory.getLocationReference())
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
                .location(inventory.getLocationReference())
                .warehouseId(inventory.getWarehouseId())
                .unique(Boolean.TRUE.equals(inventory.getIsUnique()))
                .lastChecked(inventory.getLastChecked())
                .build();
    }
}
