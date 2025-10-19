package ru.bowling.bowlingapp.Service;

import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;

import java.util.List;

public interface InventoryService {

    List<PartDto> searchParts(String query, Long clubId);

    PartDto getPartById(Long partId);

    void reservePart(ReservationRequestDto reservationRequestDto);

    void releasePart(ReservationRequestDto reservationRequestDto);

}
