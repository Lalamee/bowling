package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "mechanic_profiles")
public class MechanicProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "profile_id")
    private Long profileId;

    @OneToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "education_level_id")
    private Integer educationLevelId;

    @Column(name = "educational_institution")
    private String educationalInstitution;

    @Column(name = "total_experience_years")
    private Integer totalExperienceYears;

    @Column(name = "bowling_experience_years")
    private Integer bowlingExperienceYears;

    @Column(name = "is_entrepreneur")
    private Boolean isEntrepreneur;

    @Column(name = "specialization_id")
    private Integer specializationId;

    @Column(name = "skills")
    private String skills;

    @Column(name = "advantages")
    private String advantages;

    @Column(name = "is_data_verified")
    private Boolean isDataVerified;

    @Column(name = "verification_date")
    private LocalDate verificationDate;

    @Column(name = "rating")
    private Double rating;

    @Column(name = "created_at")
    private LocalDate createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDate updatedAt;

    @Column(name = "work_places", columnDefinition = "TEXT")
    private String workPlaces; // JSON или текст с местами работы

    @Column(name = "work_periods", columnDefinition = "TEXT")
    private String workPeriods; // JSON или текст с периодами работы

    @ManyToMany
    @JoinTable(
        name = "club_mechanics",
        joinColumns = @JoinColumn(name = "mechanic_profile_id"),
        inverseJoinColumns = @JoinColumn(name = "club_id")
    )
    private List<BowlingClub> clubs;
}