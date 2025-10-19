package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "service_history_parts")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ServiceHistoryPart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_history_id")
    private ServiceHistory serviceHistory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "part_catalog_id")
    private PartsCatalog partsCatalog;

    @Column(name = "part_name")
    private String partName;

    @Column(name = "catalog_number")
    private String catalogNumber;

    @Column(name = "quantity")
    private Integer quantity;

    @Column(name = "unit_cost")
    private Double unitCost;

    @Column(name = "total_cost")
    private Double totalCost;

    @Column(name = "warranty_months")
    private Integer warrantyMonths;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "installation_notes", columnDefinition = "TEXT")
    private String installationNotes;

    @Column(name = "created_date")
    private LocalDateTime createdDate;
}
