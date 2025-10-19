package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;

@Entity
@Table(name = "club_equipment")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ClubEquipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "equipment_id")
    private Long equipmentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private BowlingClub club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manufacturer_id")
    private Manufacturer manufacturer;

    @Column(name = "other_manufacturer_name")
    private String otherManufacturerName;

    @Column(name = "lanes_count")
    private Integer lanesCount;

    @Column(name = "model")
    private String model;

    @Column(name = "production_year")
    private Integer productionYear;

    @Column(name = "condition_percentage")
    private Integer conditionPercentage;

    @Column(name = "notes")
    private String notes;

    @Column(name = "last_maintenance_date")
    private LocalDate lastMaintenanceDate;

    @Column(name = "next_maintenance_date")
    private LocalDate nextMaintenanceDate;
}

