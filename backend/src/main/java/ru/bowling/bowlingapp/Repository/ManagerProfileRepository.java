package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.ManagerProfile;

import java.util.List;
import java.util.Optional;

public interface ManagerProfileRepository extends JpaRepository<ManagerProfile, Long> {
    Optional<ManagerProfile> findByUser_UserId(Long userId);
    List<ManagerProfile> findByClub_ClubId(Long clubId);
}
