package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicDirectoryDetailDTO {
    private Long profileId;
    private Long userId;
    private String fullName;
    private String contactPhone;
    private String specialization;
    private Double rating;
    private String status; // CLUB_MECHANIC | FREE_AGENT
    private String region;
    private List<MechanicCertificationDTO> certifications;
    private Integer totalExperienceYears;
    private Integer bowlingExperienceYears;
    private Boolean isEntrepreneur;
    private Boolean isDataVerified;
    private LocalDate verificationDate;
    private List<MechanicDirectorySummaryDTO> relatedClubs;
    private List<MechanicWorkHistoryDTO> workHistory;
    private AttestationStatus attestationStatus;
}

