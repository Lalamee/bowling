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
public class WarehouseItemResponseDTO {

    private Long clubId;

    private Long inventoryId;

    private Integer warehouseId;

    private Long catalogId;

    private String catalogNumber;

    private String officialNameRu;

    private String officialNameEn;

    private String commonName;

    private String description;

    private Integer quantity;

    private Boolean unique;

    private String location;

    private String notes;

    private LocalDate lastChecked;
}
