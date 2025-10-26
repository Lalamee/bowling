package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PartDto {

    private Long inventoryId;
    private Long catalogId;
    private String officialNameEn;
    private String officialNameRu;
    private String commonName;
    private String description;
    private String catalogNumber;
    private Integer quantity;
    private String location;
    private Integer warehouseId;
    private Boolean unique;
    private LocalDate lastChecked;

}
