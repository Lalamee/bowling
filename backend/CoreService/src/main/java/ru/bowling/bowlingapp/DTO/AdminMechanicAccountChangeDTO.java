package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminMechanicAccountChangeDTO {
    private String accountTypeName;
    private String accessLevelName;
    private Long clubId;
    private Boolean attachToClub;
}
