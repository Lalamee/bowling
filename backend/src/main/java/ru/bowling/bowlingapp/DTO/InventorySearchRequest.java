package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Service.InventoryAvailabilityFilter;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventorySearchRequest {

    private String query;
    private Integer warehouseId;
    private Long clubId; // временная поддержка для старых вызовов, дублирует warehouseId
    private String categoryCode;
    private InventoryAvailabilityFilter availability;
}
