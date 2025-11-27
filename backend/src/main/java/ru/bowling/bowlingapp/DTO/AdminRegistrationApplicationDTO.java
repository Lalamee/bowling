package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminRegistrationApplicationDTO {
    private Long userId;
    private Long profileId;
    private String phone;
    private String fullName;
    private String role;
    private String accountType;
    private String profileType;
    private Boolean isActive;
    private Boolean isVerified;
    private Boolean isProfileVerified;
    private Long clubId;
    private String clubName;
    private String submittedAt;
}
