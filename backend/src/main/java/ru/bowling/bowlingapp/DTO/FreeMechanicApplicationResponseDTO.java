package ru.bowling.bowlingapp.DTO;

import lombok.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FreeMechanicApplicationResponseDTO {
    private Long applicationId;
    private Long userId;
    private Long mechanicProfileId;
    private String phone;
    private String fullName;
    private AttestationStatus status;
    private String comment;
    private String accountType;
    private Long clubId;
    private String clubName;
    private Boolean isActive;
    private Boolean isVerified;
    private Boolean isProfileVerified;
    private LocalDate profileCreatedAt;
    private LocalDateTime submittedAt;
    private LocalDateTime updatedAt;
}
