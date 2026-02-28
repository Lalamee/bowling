package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.AttestationApplication;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttestationApplicationRepository extends JpaRepository<AttestationApplication, Long> {
    List<AttestationApplication> findAllByOrderBySubmittedAtDesc();

    List<AttestationApplication> findAllByStatusOrderBySubmittedAtDesc(ru.bowling.bowlingapp.Entity.enums.AttestationStatus status);

    Optional<AttestationApplication> findFirstByMechanicProfile_ProfileIdOrderByUpdatedAtDesc(Long profileId);

    List<AttestationApplication> findByMechanicProfile_ProfileIdAndStatus(Long profileId, ru.bowling.bowlingapp.Entity.enums.AttestationStatus status);

    List<AttestationApplication> findByStatus(ru.bowling.bowlingapp.Entity.enums.AttestationStatus status);
}
