package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

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
    private Integer reservedQuantity;
    private String location;
    private String cellCode;
    private String shelfCode;
    private Integer laneNumber;
    private String placementStatus;
    private Integer warehouseId;
    private Boolean unique;
    private LocalDate lastChecked;
    private String notes;

    private String imageUrl;
    private String diagramUrl;
    private Long equipmentNodeId;
    private List<Long> equipmentNodePath;
    private List<String> compatibility;

}
