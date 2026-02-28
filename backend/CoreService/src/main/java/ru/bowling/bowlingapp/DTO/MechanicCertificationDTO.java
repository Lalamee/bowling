package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicCertificationDTO {
    private Long certificationId;
    private String title;
    private String issuer;
    private LocalDate issueDate;
    private LocalDate expirationDate;
    private String credentialUrl;
    private String description;
}
