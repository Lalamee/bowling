package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "mechanic_work_history")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MechanicWorkHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "history_id")
    private Long historyId;

    @Column(name = "profile_id")
    private Long profileId;

    @Column(name = "workplace")
    private String workplace;

    @Column(name = "position")
    private String position;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "end_date")
    private LocalDateTime endDate;

    @Column(name = "description")
    private String description;

    @Column(name = "is_verified")
    private Boolean isVerified;
}

