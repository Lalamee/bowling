package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FreeMechanicApplicationRequestDTO {

    @NotBlank
    private String phone;

    @NotBlank
    @Size(min = 8, message = "Password must be at least 8 characters long")
    private String password;

    @NotBlank
    private String fullName;

    @NotNull
    private LocalDate birthDate;

    @NotNull
    private Integer educationLevelId;

    @NotBlank
    private String educationalInstitution;

    @NotNull
    @PositiveOrZero
    private Integer totalExperienceYears;

    @NotNull
    @PositiveOrZero
    private Integer bowlingExperienceYears;

    @NotNull
    private Boolean isEntrepreneur;

    @NotNull
    private Integer specializationId;

    @NotBlank
    private String region;

    @NotBlank
    private String skills;

    @NotBlank
    private String advantages;

    private Long clubId;

    private List<MechanicCertificationDTO> certifications;

    private List<MechanicWorkHistoryDTO> workHistory;
}
