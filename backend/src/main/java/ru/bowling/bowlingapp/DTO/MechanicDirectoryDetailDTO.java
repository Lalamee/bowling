package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

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
    private String region; // TODO: заполнить из анкеты, когда поле появится в БД
    private List<String> certifications; // TODO: заменить на отдельные DTO после появления модели сертификатов
    private Integer totalExperienceYears;
    private Integer bowlingExperienceYears;
    private Boolean isEntrepreneur;
    private Boolean isDataVerified;
    private LocalDate verificationDate;
    private List<MechanicDirectorySummaryDTO> relatedClubs;
    private String workPlaces; // TODO: нормализовать в отдельную таблицу
    private String workPeriods; // TODO: нормализовать в отдельную таблицу
    private String attestationStatus; // TODO: заменить на enum после появления модели аттестации
}

