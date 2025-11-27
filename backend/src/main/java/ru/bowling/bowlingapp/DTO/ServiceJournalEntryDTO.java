package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;

import java.time.LocalDateTime;
import java.util.List;

@Value
@Builder
public class ServiceJournalEntryDTO {
    Long workLogId;
    Long requestId;
    Integer laneNumber;
    Long equipmentId;
    String equipmentModel;
    WorkType workType;
    WorkLogStatus status;
    LocalDateTime createdDate;
    LocalDateTime completedDate;
    String mechanicName;
    List<WorkLogPartUsageDTO> partsUsed;
}
