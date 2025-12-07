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
    boolean existsByClubAndUserAndIsActiveTrue(BowlingClub club, User user);
    boolean existsByClubClubIdAndUserUserIdAndIsActiveTrue(Long clubId, Long userId);

    List<ClubStaff> findByUserUserIdAndIsActiveTrue(Long userId);

    List<ClubStaff> findByUserUserId(Long userId);
}
