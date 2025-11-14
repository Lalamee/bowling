package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseOrderDetailDTO {
    private Long orderId;
    private Long requestId;
    private Long clubId;
    private String clubName;
    private PurchaseOrderStatus status;
    private LocalDateTime orderDate;
    private LocalDateTime expectedDeliveryDate;
    private LocalDateTime actualDeliveryDate;
    private String supplierName;
    private String supplierInn;
    private String supplierContact;
    private String supplierEmail;
    private String supplierPhone;
    private List<PurchaseOrderPartDTO> parts;
    private List<SupplierReviewDTO> reviews;
    private List<SupplierReviewDTO> complaints;
}
