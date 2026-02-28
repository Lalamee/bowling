package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseOrderPartDTO {
    private Long partId;
    private String partName;
    private String catalogNumber;
    private Integer orderedQuantity;
    private Integer acceptedQuantity;
    private PartStatus status;
    private String rejectionReason;
    private String acceptanceComment;
    private Integer warehouseId;
    private Long inventoryId;
    private String inventoryLocation;
}
