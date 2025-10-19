package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;

@Entity
@Table(name = "maintenance_requests")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MaintenanceRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "request_id")
    private Long requestId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private BowlingClub club;

    @Column(name = "lane_number")
    private Integer laneNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id")
    private MechanicProfile mechanic;

    @Column(name = "request_date")
    private LocalDateTime requestDate;

    @Column(name = "completion_date")
    private LocalDateTime completionDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private MaintenanceRequestStatus status;

    @Column(name = "manager_notes")
    private String managerNotes;

    @Column(name = "manager_decision_date")
    private LocalDateTime managerDecisionDate;

    @Column(name = "verification_status")
    private String verificationStatus;

    @Column(name = "published_at")
    private java.time.LocalDateTime publishedAt;

    @Column(name = "assigned_agent_id")
    private Long assignedAgentId;
}

