package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.OwnerProfile;

import java.util.Optional;

public interface OwnerProfileRepository extends JpaRepository<OwnerProfile, Long> {
    Optional<OwnerProfile> findByUser_UserId(Long userId);
}

