package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WarehouseItemRequestDTO {

    private Long inventoryId;

    private Long catalogId;

    private String catalogNumber;

    private String officialNameRu;

    private String officialNameEn;

    private String commonName;

    private String description;

    private Integer quantity;

    private Boolean replaceQuantity;

    private String location;

    private Boolean unique;

    private String notes;
}
