package ru.bowling.bowlingapp.DTO;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MaintenanceRequestResponseDTO {

    private Long requestId;
    private Long clubId;
    private String clubName;
    private Integer laneNumber;
    private Long mechanicId;
    private String mechanicName;
    private LocalDateTime requestDate;
    private LocalDateTime completionDate;
    private String status;
    private String managerNotes;
    private LocalDateTime managerDecisionDate;
    private String verificationStatus;
    private String reason;
    
    private List<RequestPartResponseDTO> requestedParts;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class RequestPartResponseDTO {
        private Long partId;
        private String catalogNumber;
        private String partName;
        private Integer quantity;
        private Long inventoryId;
        private Long catalogId;
        private Integer warehouseId;
        private String inventoryLocation;
        private String status;
        private String rejectionReason;
        private Long supplierId;
        private String supplierName;
        private LocalDateTime orderDate;
        private LocalDateTime deliveryDate;
        private LocalDateTime issueDate;
        private Boolean available;
        private Integer acceptedQuantity;
        private String acceptanceComment;
        private LocalDateTime acceptanceDate;

        // Индикатор "просьбы о помощи" по позиции заявки
        private Boolean helpRequested;
    }
}
