package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ru.bowling.bowlingapp.Entity.MechanicProfile;

import java.util.List;
import java.util.Optional;

public interface MechanicProfileRepository extends JpaRepository<MechanicProfile, Long> {
    List<MechanicProfile> findAllByUser_UserIdOrderByProfileIdDesc(Long userId);
    List<MechanicProfile> findByClubs_ClubId(Long clubId);

    @Query("""
            SELECT DISTINCT mp
            FROM MechanicProfile mp
            LEFT JOIN FETCH mp.user u
            LEFT JOIN FETCH mp.clubs c
            """)
    List<MechanicProfile> findAllWithUserAndClubs();

    @Query("""
            SELECT mp
            FROM MechanicProfile mp
            LEFT JOIN FETCH mp.user u
            LEFT JOIN FETCH mp.clubs c
            LEFT JOIN FETCH mp.certifications cert
            LEFT JOIN FETCH mp.workHistoryEntries history
            WHERE mp.profileId = :profileId
            """)
    Optional<MechanicProfile> findDetailedById(@Param("profileId") Long profileId);
}
