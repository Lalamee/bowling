package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.ClubInvitation;

public interface ClubInvitationRepository extends JpaRepository<ClubInvitation, Long> {
}
