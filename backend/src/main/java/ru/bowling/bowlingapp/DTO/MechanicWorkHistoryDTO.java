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
public class MechanicWorkHistoryDTO {
    private Long historyId;
    private String organization;
    private String position;
    private LocalDate startDate;
    private LocalDate endDate;
    private String description;
}
