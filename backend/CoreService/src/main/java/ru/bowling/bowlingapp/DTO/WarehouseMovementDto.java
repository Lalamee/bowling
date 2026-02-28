package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WarehouseMovementDto {
    private String operationType;
    private Integer quantityDelta;
    private Long inventoryId;
    private Integer catalogId;
    private Integer warehouseId;
    private String comment;
    private LocalDateTime occurredAt;
}
