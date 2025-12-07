package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminMechanicStatusChangeDTO {
    private Long staffId;
    private Long userId;
    private Long mechanicProfileId;
    private Long clubId;
    private String clubName;
    private String role;
    private Boolean isActive;
    private Boolean infoAccessRestricted;
}
