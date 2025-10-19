package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

import ru.bowling.bowlingapp.Entity.enums.PartStatus;

@Entity
@Table(name = "request_parts")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class RequestPart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "part_id")
    private Long partId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "request_id")
    private MaintenanceRequest request;

    @Column(name = "catalog_number")
    private String catalogNumber;

    @Column(name = "part_name")
    private String partName;

    @Column(name = "quantity")
    private Integer quantity;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private PartStatus status;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "order_date")
    private LocalDateTime orderDate;

    @Column(name = "delivery_date")
    private LocalDateTime deliveryDate;

    @Column(name = "issue_date")
    private LocalDateTime issueDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    private PurchaseOrder purchaseOrder;
}
