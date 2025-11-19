package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Table(name = "mechanic_certifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicCertification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "certification_id")
    private Long certificationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_profile_id", nullable = false)
    private MechanicProfile mechanicProfile;

    @Column(name = "title")
    private String title;

    @Column(name = "issuer")
    private String issuer;

    @Column(name = "issue_date")
    private LocalDate issueDate;

    @Column(name = "expiration_date")
    private LocalDate expirationDate;

    @Column(name = "credential_url")
    private String credentialUrl;

    @Column(name = "description")
    private String description;
}
