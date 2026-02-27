package ru.bowling.bowlingapp.integration.onec.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OneCStockItemDto {
    private String productCode;
    private String catalogNumber;
    private Integer warehouseId;
    private Integer quantity;
    private Integer reservedQuantity;
    private String location;
}
