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
    private Integer reservedQuantity; // TODO: заполнить, когда бэкенд начнёт хранить резерв по складу
    private String location;
    private String cellCode; // TODO: ожидается код ячейки (cellCode) от API
    private String shelfCode; // TODO: ожидается код стеллажа (shelfCode) от API
    private Integer laneNumber; // TODO: требуется номер дорожки для адресного хранения
    private String placementStatus; // TODO: статус размещения (на складе / на дорожке)
    private Integer warehouseId;
    private Boolean unique;
    private LocalDate lastChecked;

}
