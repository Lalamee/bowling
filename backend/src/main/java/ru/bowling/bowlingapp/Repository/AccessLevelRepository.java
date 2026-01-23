package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.AccessLevel;

import java.util.Optional;

public interface AccessLevelRepository extends JpaRepository<AccessLevel, Integer> {
    Optional<AccessLevel> findByNameIgnoreCase(String name);
}
