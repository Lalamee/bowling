package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.BowlingClub;

@Repository
public interface BowlingClubRepository extends JpaRepository<BowlingClub, Long> {
}
