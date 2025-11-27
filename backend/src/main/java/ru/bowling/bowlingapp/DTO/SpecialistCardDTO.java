package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpecialistCardDTO {
    private Long profileId;
    private Long userId;
    private String fullName;
    private String region;
    private Integer specializationId;
    private String skills;
    private String advantages;
    private Integer totalExperienceYears;
    private Integer bowlingExperienceYears;
    private Boolean isEntrepreneur;
    private Double rating;
    private MechanicGrade attestedGrade;
    private String accountType;
    private LocalDate verificationDate;
    private List<String> clubs;
}
