package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.ServiceType;

import java.time.LocalDateTime;
import java.util.List;

@Value
@Builder
public class ServiceJournalEntryDTO {
    Long workLogId;
    Long requestId;
    Long serviceHistoryId;
    Integer laneNumber;
    Long equipmentId;
    String equipmentModel;
    WorkType workType;
    ServiceType serviceType;
    WorkLogStatus status;
    MaintenanceRequestStatus requestStatus;
    LocalDateTime createdDate;
    LocalDateTime completedDate;
    LocalDateTime serviceDate;
    String mechanicName;
    List<WorkLogPartUsageDTO> partsUsed;
}
