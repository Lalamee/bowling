package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "bowling_clubs")
public class BowlingClub {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "club_id")
    private Long clubId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private OwnerProfile owner;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "lanes_count")
    private Integer lanesCount;

    @Column(name = "contact_phone")
    private String contactPhone;

    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "is_verified")
    private Boolean isVerified;

    @Column(name = "verification_date")
    private LocalDate verificationDate;

    @Column(name = "created_at")
    private LocalDate createdAt;

    @Column(name = "updated_at")
    private LocalDate updatedAt;

    @OneToMany(mappedBy = "club", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ClubEquipmentType> equipmentTypes;

    @PrePersist
    public void applyDefaults() {
        if (address == null || address.isBlank()) {
            address = "N/A";
        }
        if (isActive == null) {
            isActive = Boolean.TRUE;
        }
        if (isVerified == null) {
            isVerified = Boolean.FALSE;
        }
        if (createdAt == null) {
            createdAt = LocalDate.now();
        }
        if (updatedAt == null) {
            updatedAt = createdAt;
        }
    }
}