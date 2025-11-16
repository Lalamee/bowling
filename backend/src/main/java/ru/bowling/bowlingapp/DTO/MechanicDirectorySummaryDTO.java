package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicDirectorySummaryDTO {
    private Long profileId;
    private String fullName;
    private String specialization;
    private Double rating;
    private String status; // CLUB_MECHANIC | FREE_AGENT
    private String region; // TODO: заполнить из анкеты, когда поле появится в БД
    private List<String> clubs;
    private List<String> certifications; // TODO: заменить на отдельные DTO после появления модели сертификатов
}

