package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;

@Entity
@Table(name = "equipment_maintenance_schedule")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class EquipmentMaintenanceSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "schedule_id")
    private Long scheduleId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private BowlingClub club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipment_id")
    private ClubEquipment equipment;

    @Column(name = "maintenance_type")
    private String maintenanceType;

    @Column(name = "scheduled_date")
    private LocalDate scheduledDate;

    @Column(name = "last_performed")
    private LocalDate lastPerformed;

    @Column(name = "is_critical")
    private Boolean isCritical;
}

