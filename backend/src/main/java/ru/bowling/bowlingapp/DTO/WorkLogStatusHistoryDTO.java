package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WorkLogStatusHistoryDTO {

    private Long historyId;
    private Long workLogId;
    private String previousStatus;
    private String newStatus;
    private LocalDateTime changedDate;
    private Long changedByUserId;
    private String changedByUserName;
    private String reason;
    private String additionalNotes;
}
