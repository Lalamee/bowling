package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import ru.bowling.bowlingapp.Entity.converter.WorkTypeConverter;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "work_logs")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WorkLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Long logId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "maintenance_request_id")
    private MaintenanceRequest maintenanceRequest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private BowlingClub club;

    @Column(name = "lane_number")
    private Integer laneNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipment_id")
    private ClubEquipment equipment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id")
    private MechanicProfile mechanic;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    @Column(name = "started_date")
    private LocalDateTime startedDate;

    @Column(name = "completed_date")
    private LocalDateTime completedDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private WorkLogStatus status;

    @Convert(converter = WorkTypeConverter.class)
    @Column(name = "work_type")
    private WorkType workType;

    @Column(name = "problem_description", columnDefinition = "TEXT")
    private String problemDescription;

    @Column(name = "work_performed", columnDefinition = "TEXT")
    private String workPerformed;

    @Column(name = "solution_description", columnDefinition = "TEXT")
    private String solutionDescription;

    @Column(name = "estimated_hours")
    private Double estimatedHours;

    @Column(name = "actual_hours")
    private Double actualHours;

    @Column(name = "labor_cost")
    private Double laborCost;

    @Column(name = "total_parts_cost")
    private Double totalPartsCost;

    @Column(name = "total_cost")
    private Double totalCost;

    @Column(name = "priority")
    private Integer priority; // 1-5, где 1 - критично, 5 - низкий приоритет

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Column(name = "approval_date")
    private LocalDateTime approvalDate;

    @Column(name = "manager_notes", columnDefinition = "TEXT")
    private String managerNotes;

    @Column(name = "quality_rating")
    private Integer qualityRating; // 1-10

    @Column(name = "customer_satisfaction")
    private Integer customerSatisfaction; // 1-10

    @Column(name = "photos", columnDefinition = "TEXT")
    private String photos; // JSON массив URL фотографий

    @Column(name = "warranty_period_months")
    private Integer warrantyPeriodMonths;

    @Column(name = "next_service_date")
    private LocalDateTime nextServiceDate;

    @Column(name = "version")
    @Version
    private Long version;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "modified_by")
    private Long modifiedBy;

    @Column(name = "modified_date")
    private LocalDateTime modifiedDate;

    @Column(name = "is_manual_edit")
    @Builder.Default
    private Boolean isManualEdit = false;

    @Column(name = "manual_edit_reason")
    private String manualEditReason;

    @OneToMany(mappedBy = "workLog", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<WorkLogPartUsage> partsUsed;

    @OneToMany(mappedBy = "workLog", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<WorkLogStatusHistory> statusHistory;
}
