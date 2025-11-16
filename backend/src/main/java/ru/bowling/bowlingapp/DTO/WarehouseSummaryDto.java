package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Service.WarehouseType;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WarehouseSummaryDto {

    private Integer warehouseId;
    private Long clubId;
    private String clubName;
    private WarehouseType warehouseType;
    private Integer totalPositions; // TODO: приходит с агрегации складов
    private Integer lowStockPositions; // TODO: приходит с агрегации складов
    private Integer reservedPositions; // TODO: заполнить, когда появится reservedQuantity в БД
    private Boolean personalAccess;
}
