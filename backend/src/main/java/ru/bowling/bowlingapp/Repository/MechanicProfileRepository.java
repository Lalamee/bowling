package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import ru.bowling.bowlingapp.Entity.MechanicProfile;

import java.util.List;
import java.util.Optional;

public interface MechanicProfileRepository extends JpaRepository<MechanicProfile, Long> {
    Optional<MechanicProfile> findByUser_UserId(Long userId);
    List<MechanicProfile> findByClubs_ClubId(Long clubId);

    @EntityGraph(attributePaths = {"user", "clubs"})
    List<MechanicProfile> findAllWithUserAndClubs();
}

