package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.Entity.AttestationApplication;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Repository.AttestationApplicationRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class AttestationService {

    private final AttestationApplicationRepository attestationApplicationRepository;
    private final UserRepository userRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final BowlingClubRepository bowlingClubRepository;

    @Transactional(readOnly = true)
    public List<AttestationApplicationDTO> listApplications() {
        return attestationApplicationRepository.findAllByOrderBySubmittedAtDesc()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AttestationApplicationDTO submitApplication(AttestationApplicationDTO dto) {
        LocalDateTime now = LocalDateTime.now();
        AttestationApplication entity = AttestationApplication.builder()
                .user(resolveUser(dto.getUserId()))
                .mechanicProfile(resolveMechanic(dto.getMechanicProfileId()))
                .club(resolveClub(dto.getClubId()))
                .requestedGrade(dto.getRequestedGrade())
                .comment(dto.getComment())
                .status(dto.getStatus() != null ? dto.getStatus() : AttestationStatus.NEW)
                .submittedAt(now)
                .updatedAt(now)
                .build();

        AttestationApplication saved = attestationApplicationRepository.save(entity);
        log.info("Attestation application saved: {}", saved.getApplicationId());
        return toDto(saved);
    }

    @Transactional
    public AttestationApplicationDTO updateStatus(Long applicationId, String statusCode, String comment) {
        AttestationApplication application = attestationApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

        AttestationStatus status = AttestationStatus.fromCode(statusCode);
        if (status == AttestationStatus.REJECTED && (comment == null || comment.isBlank())) {
            throw new IllegalArgumentException("Comment is required when rejecting an application");
        }

        application.setStatus(status);
        application.setComment(comment);
        application.setUpdatedAt(LocalDateTime.now());

        AttestationApplication saved = attestationApplicationRepository.save(application);
        return toDto(saved);
    }

    private AttestationApplicationDTO toDto(AttestationApplication entity) {
        if (entity == null) {
            return null;
        }
        return AttestationApplicationDTO.builder()
                .id(entity.getApplicationId())
                .userId(entity.getUser() != null ? entity.getUser().getUserId() : null)
                .mechanicProfileId(entity.getMechanicProfile() != null ? entity.getMechanicProfile().getProfileId() : null)
                .clubId(entity.getClub() != null ? entity.getClub().getClubId() : null)
                .status(entity.getStatus())
                .comment(entity.getComment())
                .requestedGrade(entity.getRequestedGrade())
                .submittedAt(entity.getSubmittedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private User resolveUser(Long userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
    }

    private MechanicProfile resolveMechanic(Long mechanicProfileId) {
        if (mechanicProfileId == null) {
            return null;
        }
        return mechanicProfileRepository.findById(mechanicProfileId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic profile not found: " + mechanicProfileId));
    }

    private BowlingClub resolveClub(Long clubId) {
        if (clubId == null) {
            return null;
        }
        return bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found: " + clubId));
    }
}

