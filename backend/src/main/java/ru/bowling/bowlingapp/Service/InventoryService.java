package ru.bowling.bowlingapp.Service;

import ru.bowling.bowlingapp.DTO.InventorySearchRequest;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.WarehouseSummaryDto;

import java.util.List;

public interface InventoryService {

    List<PartDto> searchParts(InventorySearchRequest request);

    PartDto getPartById(Long partId);

    void reservePart(ReservationRequestDto reservationRequestDto);

    void releasePart(ReservationRequestDto reservationRequestDto);

    List<WarehouseSummaryDto> getAccessibleWarehouses(Long userId);

}
