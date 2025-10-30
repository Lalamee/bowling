package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicProfileDTO {
    @NotBlank
    private String fullName;

    @NotNull
    private LocalDate birthDate;

    private Integer educationLevelId;
    private String educationalInstitution;

    @NotNull
    private Integer totalExperienceYears;

    @NotNull
    private Integer bowlingExperienceYears;

    private Boolean isEntrepreneur;

    private Integer specializationId;
    private String skills;
    private String advantages;

    // Дополнительные поля для работы
    private String workPlaces; // Места работы (JSON или текст)
    private String workPeriods; // Периоды работы (JSON или текст)

    private Long clubId;
}

