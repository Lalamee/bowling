package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryItemRequest {

        private Integer warehouseId;

        private Long clubId;

        @NotNull(message = "Catalog ID is required")
        private Long catalogId;

        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least 1")
        private Integer quantity;

        private Integer reservedQuantity;

        @Size(max = 255)
        private String locationReference;

        @Size(max = 50)
        private String cellCode;

        @Size(max = 50)
        private String shelfCode;

        private Integer laneNumber;

        @Size(max = 255)
        private String placementStatus;

        @Size(max = 1000)
        private String notes;

        private Boolean isUnique;
}
