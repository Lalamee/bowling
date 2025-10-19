package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "work_log_part_usage")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WorkLogPartUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "usage_id")
    private Long usageId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "work_log_id")
    private WorkLog workLog;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "part_catalog_id")
    private PartsCatalog partsCatalog;

    @Column(name = "part_name")
    private String partName;

    @Column(name = "catalog_number")
    private String catalogNumber;

    @Column(name = "quantity_used")
    private Integer quantityUsed;

    @Column(name = "unit_cost")
    private Double unitCost;

    @Column(name = "total_cost")
    private Double totalCost;

    @Column(name = "sourced_from")
    private String sourcedFrom; // INVENTORY, SUPPLIER, MECHANIC_PURCHASE

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "invoice_number")
    private String invoiceNumber;

    @Column(name = "warranty_months")
    private Integer warrantyMonths;

    @Column(name = "installed_date")
    private LocalDateTime installedDate;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    @Column(name = "created_by")
    private Long createdBy;
}
