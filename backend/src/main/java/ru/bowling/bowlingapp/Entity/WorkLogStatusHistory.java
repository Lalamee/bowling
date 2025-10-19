package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;

import java.time.LocalDateTime;

@Entity
@Table(name = "work_log_status_history")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WorkLogStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "history_id")
    private Long historyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "work_log_id")
    private WorkLog workLog;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status")
    private WorkLogStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status")
    private WorkLogStatus newStatus;

    @Column(name = "changed_date")
    private LocalDateTime changedDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "changed_by")
    private User changedBy;

    @Column(name = "reason", columnDefinition = "TEXT")
    private String reason;

    @Column(name = "additional_notes", columnDefinition = "TEXT")
    private String additionalNotes;
}
