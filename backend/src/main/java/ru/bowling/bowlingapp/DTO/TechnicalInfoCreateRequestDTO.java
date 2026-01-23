package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TechnicalInfoCreateRequestDTO {
    private Long clubId;
    private String equipmentType;
    private String manufacturer;
    private String model;
    private String serialNumber;
    private Integer lanesCount;
    private Integer productionYear;
    private Integer conditionPercentage;
    private LocalDate purchaseDate;
    private LocalDate warrantyUntil;
    private String status;
    private LocalDate lastMaintenanceDate;
    private LocalDate nextMaintenanceDate;
}
