package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.MechanicProfile;

import java.util.Optional;

public interface MechanicProfileRepository extends JpaRepository<MechanicProfile, Long> {
    Optional<MechanicProfile> findByUser_UserId(Long userId);
}

