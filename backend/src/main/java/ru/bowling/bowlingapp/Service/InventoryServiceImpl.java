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
import java.util.stream.Collectors;

@Service
public class InventoryServiceImpl implements InventoryService {

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Override
    public List<PartDto> searchParts(String query, Long clubId) {
        List<PartsCatalog> parts = partsCatalogRepository.searchByNameOrNumber(query);
        return parts.stream().map(this::convertToDto).collect(Collectors.toList());
    }

    @Override
    public PartDto getPartById(Long partId) {
        PartsCatalog part = partsCatalogRepository.findById(partId)
                .orElseThrow(() -> new RuntimeException("Part not found"));
        return convertToDto(part);
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
        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
        WarehouseInventory inventory = inventories.isEmpty() ? null : inventories.get(0);
        int quantity = (inventory != null) ? inventory.getQuantity() : 0;
        String location = (inventory != null) ? inventory.getLocationReference() : "N/A";

        return new PartDto(
                part.getCatalogId(),
                part.getOfficialNameEn(),
                part.getOfficialNameRu(),
                part.getCommonName(),
                part.getDescription(),
                part.getCatalogNumber(),
                quantity,
                location
        );
    }
}
