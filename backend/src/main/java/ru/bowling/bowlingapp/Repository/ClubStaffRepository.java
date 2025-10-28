package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.ClubStaff;
import ru.bowling.bowlingapp.Entity.User;

import java.util.List;
import java.util.Optional;

public interface ClubStaffRepository extends JpaRepository<ClubStaff, Long> {
    Optional<ClubStaff> findByClubAndUser(BowlingClub club, User user);
    boolean existsByClubAndUser(BowlingClub club, User user);

    List<ClubStaff> findByUserUserIdAndIsActiveTrue(Long userId);
}
