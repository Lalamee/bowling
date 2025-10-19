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
@Table(name = "club_owners")
public class OwnerProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "owner_id")
    private Long ownerId;

    @OneToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "inn")
    private String inn;

    @Column(name = "legal_name")
    private String legalName;

    @Column(name = "contact_person")
    private String contactPerson;

    @Column(name = "contact_phone")
    private String contactPhone;

    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "is_data_verified")
    private Boolean isDataVerified;

    @Column(name = "verification_date")
    private LocalDate verificationDate;

    @Column(name = "created_at")
    private LocalDate createdAt;

    @Column(name = "updated_at")
    private LocalDate updatedAt;

    @OneToMany(mappedBy = "owner")
    private List<BowlingClub> clubs;
}
