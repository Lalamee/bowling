package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;

@Entity
@Table(name = "warehouse_inventory")
@Data
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

    @Column(name = "location_reference")
    private String locationReference;

    @Column(name = "last_checked")
    private LocalDate lastChecked;

    @Column(name = "notes")
    private String notes;

    @Column(name = "is_unique")
    private Boolean isUnique;
}
