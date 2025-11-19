package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.AttestationApplication;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttestationApplicationRepository extends JpaRepository<AttestationApplication, Long> {
    List<AttestationApplication> findAllByOrderBySubmittedAtDesc();

    Optional<AttestationApplication> findFirstByMechanicProfile_ProfileIdOrderByUpdatedAtDesc(Long profileId);
}
