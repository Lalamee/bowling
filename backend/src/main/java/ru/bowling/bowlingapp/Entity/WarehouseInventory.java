package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "warehouse_inventory")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WarehouseInventory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "inventory_id")
    private Long inventoryId;

    @Column(name = "warehouse_id")
    private Integer warehouseId;

    @Column(name = "catalog_id")
    private Integer catalogId;

    @Column(name = "quantity")
    private Integer quantity;

    @Column(name = "reserved_quantity")
    private Integer reservedQuantity;

    @Column(name = "location_reference")
    private String locationReference;

    @Column(name = "cell_code")
    private String cellCode;

    @Column(name = "shelf_code")
    private String shelfCode;

    @Column(name = "lane_number")
    private Integer laneNumber;

    @Column(name = "placement_status")
    private String placementStatus;

    @Column(name = "last_checked")
    private LocalDate lastChecked;

    @Column(name = "notes")
    private String notes;

    @Column(name = "is_unique")
    private Boolean isUnique;
}
