package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import ru.bowling.bowlingapp.Entity.enums.ServiceType;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "service_history")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ServiceHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "service_id")
    private Long serviceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private BowlingClub club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipment_id")
    private ClubEquipment equipment;

    @Column(name = "lane_number")
    private Integer laneNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_type")
    private ServiceType serviceType;

    @Column(name = "service_date")
    private LocalDateTime serviceDate;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "parts_replaced", columnDefinition = "TEXT")
    private String partsReplaced;

    @Column(name = "labor_hours")
    private Double laborHours;

    @Column(name = "total_cost")
    private Double totalCost;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "performed_by")
    private MechanicProfile performedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supervised_by")
    private User supervisedBy;

    @Column(name = "next_service_due")
    private LocalDateTime nextServiceDue;

    @Column(name = "warranty_until")
    private LocalDateTime warrantyUntil;

    @Column(name = "service_notes", columnDefinition = "TEXT")
    private String serviceNotes;

    @Column(name = "performance_metrics", columnDefinition = "TEXT")
    private String performanceMetrics;

    @Column(name = "photos", columnDefinition = "TEXT")
    private String photos;

    @Column(name = "documents", columnDefinition = "TEXT")
    private String documents;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    @Column(name = "created_by")
    private Long createdBy;

    @OneToMany(mappedBy = "serviceHistory", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<ServiceHistoryPart> partsUsed;
}
