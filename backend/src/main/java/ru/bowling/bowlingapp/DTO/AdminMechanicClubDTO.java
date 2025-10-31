package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AdminMechanicClubDTO {
    private Long clubId;
    private String clubName;
    private String address;
    private String contactPhone;
    private String contactEmail;
    private List<AdminMechanicSummaryDTO> mechanics;
}
