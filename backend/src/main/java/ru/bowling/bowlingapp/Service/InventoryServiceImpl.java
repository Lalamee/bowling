package ru.bowling.bowlingapp.Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.util.List;
import java.util.Objects;
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
        if (normalizedQuery.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        List<PartsCatalog> parts = partsCatalogRepository.searchByNameOrNumber(normalizedQuery);
        if (parts.isEmpty()) {
            return java.util.Collections.emptyList();
        }

        Integer warehouseId = clubId != null ? clubId.intValue() : null;

        return parts.stream()
                .map(part -> convertToDto(part, warehouseId))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    @Override
    public PartDto getPartById(Long partId) {
        PartsCatalog part = partsCatalogRepository.findById(partId)
                .orElseThrow(() -> new RuntimeException("Part not found"));
        PartDto dto = convertToDto(part, null);
        if (dto == null) {
            return new PartDto(
                    part.getCatalogId(),
                    part.getOfficialNameEn(),
                    part.getOfficialNameRu(),
                    part.getCommonName(),
                    part.getDescription(),
                    part.getCatalogNumber(),
                    0,
                    null
            );
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

    private PartDto convertToDto(PartsCatalog part) {
        return convertToDto(part, null);
    }

    private PartDto convertToDto(PartsCatalog part, Integer warehouseFilterId) {
        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
        int totalQuantity = 0;
        String location = null;

        for (WarehouseInventory inventory : inventories) {
            Integer quantity = inventory.getQuantity();
            if (quantity == null || quantity <= 0) {
                continue;
            }
            if (warehouseFilterId != null && !warehouseFilterId.equals(inventory.getWarehouseId())) {
                continue;
            }
            totalQuantity += quantity;
            if (location == null) {
                String reference = inventory.getLocationReference();
                if (reference != null && !reference.isBlank()) {
                    location = reference;
                }
            }
        }

        if (totalQuantity <= 0) {
            return null;
        }

        return new PartDto(
                part.getCatalogId(),
                part.getOfficialNameEn(),
                part.getOfficialNameRu(),
                part.getCommonName(),
                part.getDescription(),
                part.getCatalogNumber(),
                totalQuantity,
                location
        );
    }
}
