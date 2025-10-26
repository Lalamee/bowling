package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.AdministratorProfile;

import java.util.List;

public interface AdministratorProfileRepository extends JpaRepository<AdministratorProfile, Long> {
    List<AdministratorProfile> findByClub_ClubId(Long clubId);
}
