package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class WorkLogPartUsageDTO {
    Long usageId;
    String partName;
    String catalogNumber;
    Integer quantityUsed;
    Double totalCost;
}
