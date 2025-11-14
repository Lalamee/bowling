package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseOrderSummaryDTO {
    private Long orderId;
    private Long requestId;
    private Long clubId;
    private String clubName;
    private String supplierName;
    private String supplierInn;
    private PurchaseOrderStatus status;
    private LocalDateTime orderDate;
    private LocalDateTime expectedDeliveryDate;
    private LocalDateTime actualDeliveryDate;
    private Integer totalPositions;
    private Integer acceptedPositions;
    private boolean hasReview;
    private boolean hasComplaint;
}
