package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminMechanicSummaryDTO {
    private Long userId;
    private Long profileId;
    private String fullName;
    private String phone;
    private Boolean isActive;
    private Boolean isVerified;
    private Boolean isDataVerified;
}
