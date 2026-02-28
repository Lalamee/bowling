package ru.bowling.bowlingapp.Service;

import ru.bowling.bowlingapp.DTO.*;

import java.util.List;

public interface InventoryService {

    List<PartDto> searchParts(InventorySearchRequest request);

    PartDto getPartById(Long partId);

    void reservePart(ReservationRequestDto reservationRequestDto);

    void releasePart(ReservationRequestDto reservationRequestDto);

    List<WarehouseSummaryDto> getAccessibleWarehouses(Long userId);

    List<WarehouseMovementDto> getWarehouseMovements(Integer warehouseId);

    PartDto addInventoryItem(Long userId, InventoryItemRequest request);

}
