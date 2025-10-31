package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AdminMechanicListResponseDTO {
    private List<AdminPendingMechanicDTO> pending;
    private List<AdminMechanicClubDTO> clubs;
}
