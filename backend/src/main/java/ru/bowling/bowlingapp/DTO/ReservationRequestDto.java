package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ReservationRequestDto {

    private Long partId;
    private Integer quantity;
    private Long maintenanceRequestId;

}
