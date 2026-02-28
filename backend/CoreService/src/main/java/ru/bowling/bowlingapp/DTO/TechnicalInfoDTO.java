package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDate;
import java.util.List;

@Value
@Builder
public class TechnicalInfoDTO {
    Long equipmentId;
    String model;
    String serialNumber;
    String equipmentType;
    String manufacturer;
    Integer productionYear;
    Integer lanesCount;
    Integer conditionPercentage;
    LocalDate purchaseDate;
    LocalDate warrantyUntil;
    String status;
    LocalDate lastMaintenanceDate;
    LocalDate nextMaintenanceDate;
    List<EquipmentComponentDTO> components;
    List<MaintenanceScheduleDTO> schedules;
}
