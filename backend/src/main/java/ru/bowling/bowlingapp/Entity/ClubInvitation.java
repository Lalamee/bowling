package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "club_invitations")
@Data
public class ClubInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private BowlingClub club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id", nullable = false)
    private User mechanic;

    @Column(nullable = false)
    private String status; // PENDING, ACCEPTED, REJECTED
}
