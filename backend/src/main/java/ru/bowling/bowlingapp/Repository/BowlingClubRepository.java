package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.BowlingClub;

import java.util.List;
import java.util.Optional;

@Repository
public interface BowlingClubRepository extends JpaRepository<BowlingClub, Long> {
    Optional<BowlingClub> findByNameIgnoreCaseAndAddressIgnoreCase(String name, String address);

    List<BowlingClub> findAllByOwnerOwnerId(Long ownerId);
}
