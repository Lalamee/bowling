package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

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

    private String region;
    private List<MechanicCertificationDTO> certifications;
    private List<MechanicWorkHistoryDTO> workHistory;

    private Long clubId;
}

