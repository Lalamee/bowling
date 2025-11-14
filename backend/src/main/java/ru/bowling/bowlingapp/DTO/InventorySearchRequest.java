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
    private Long clubId; // TODO: убрать, когда все вызовы перейдут на warehouseId
    private String categoryCode; // TODO: заполнить, когда появится категория в PartsCatalog
    private InventoryAvailabilityFilter availability;
}
