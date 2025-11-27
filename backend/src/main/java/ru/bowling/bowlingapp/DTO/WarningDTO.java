package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDate;

@Value
@Builder
public class WarningDTO {
    String type;
    String message;
    Long equipmentId;
    Long scheduleId;
    Long partCatalogId;
    LocalDate dueDate;
}
