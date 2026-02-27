package ru.bowling.bowlingapp.integration.onec.mapper;

import org.springframework.stereotype.Component;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.integration.onec.dto.OneCStockItemDto;

import java.time.LocalDate;

@Component
public class OneCInventoryMapper {

    public WarehouseInventory toWarehouseInventory(Integer catalogId, OneCStockItemDto source, WarehouseInventory target) {
        WarehouseInventory inventory = target == null ? new WarehouseInventory() : target;
        inventory.setCatalogId(catalogId);
        inventory.setWarehouseId(source.getWarehouseId());
        inventory.setQuantity(source.getQuantity() != null ? source.getQuantity() : 0);
        inventory.setReservedQuantity(source.getReservedQuantity() != null ? source.getReservedQuantity() : 0);
        inventory.setLocationReference(source.getLocation());
        inventory.setLastChecked(LocalDate.now());
        inventory.setNotes("Synced from 1C");
        return inventory;
    }
}
