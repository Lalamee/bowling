package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "maintenance_history")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MaintenanceHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "history_id")
    private Long historyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private BowlingClub club;

    @Column(name = "lane_number")
    private Integer laneNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id")
    private MechanicProfile mechanic;

    @Column(name = "work_date")
    private LocalDateTime workDate;

    @Column(name = "work_description")
    private String workDescription;

    @Column(name = "parts_used")
    private String partsUsed;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manager_id")
    private User manager;

    @Column(name = "manager_approval_date")
    private LocalDateTime managerApprovalDate;

    @Column(name = "quality_rating")
    private Integer qualityRating;

    @Column(name = "manager_notes")
    private String managerNotes;
}

