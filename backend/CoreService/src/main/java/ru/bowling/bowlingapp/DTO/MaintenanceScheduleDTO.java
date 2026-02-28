package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDate;

@Value
@Builder
public class MaintenanceScheduleDTO {
    Long scheduleId;
    String maintenanceType;
    LocalDate scheduledDate;
    LocalDate lastPerformed;
    Boolean critical;
}
