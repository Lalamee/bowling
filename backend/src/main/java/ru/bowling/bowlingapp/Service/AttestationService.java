package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.DTO.AttestationDecisionDTO;
import ru.bowling.bowlingapp.Entity.AttestationApplication;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Repository.AttestationApplicationRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
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
    public List<AttestationApplicationDTO> listApplications(AttestationDecisionStatus status) {
        List<AttestationApplication> applications = status == null
                ? attestationApplicationRepository.findAllByOrderBySubmittedAtDesc()
                : attestationApplicationRepository.findAllByStatusOrderBySubmittedAtDesc(status.toEntityStatus());

        return applications
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AttestationApplicationDTO submitApplication(AttestationApplicationDTO dto) {
        validateSubmission(dto);
        LocalDateTime now = LocalDateTime.now();
        AttestationApplication entity = AttestationApplication.builder()
                .user(resolveActiveUser(dto.getUserId()))
                .mechanicProfile(resolveMechanic(dto.getMechanicProfileId()))
                .club(resolveClub(dto.getClubId()))
                .requestedGrade(dto.getRequestedGrade())
                .comment(dto.getComment())
                .status(AttestationStatus.PENDING)
                .submittedAt(now)
                .updatedAt(now)
                .build();

        AttestationApplication saved = attestationApplicationRepository.save(entity);
        log.info("Attestation application saved: {}", saved.getApplicationId());
        return toDto(saved);
    }

    @Transactional
    public AttestationApplicationDTO updateStatus(Long applicationId, AttestationDecisionDTO decision) {
        if (decision == null || decision.getStatus() == null) {
            throw new IllegalArgumentException("Decision status is required");
        }
        AttestationApplication application = attestationApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

        AttestationDecisionStatus status = decision.getStatus();
        if (status == AttestationDecisionStatus.REJECTED && (decision.getComment() == null || decision.getComment().isBlank())) {
            throw new IllegalArgumentException("Comment is required when rejecting an application");
        }

        if (status == AttestationDecisionStatus.APPROVED) {
            markApproved(application, decision.getApprovedGrade());
        } else {
            application.setStatus(status.toEntityStatus());
        }
        application.setComment(decision.getComment());
        application.setUpdatedAt(LocalDateTime.now());

        return toDto(attestationApplicationRepository.save(application));
    }

    private AttestationApplicationDTO toDto(AttestationApplication entity) {
        if (entity == null) {
            return null;
        }
        User user = entity.getUser();
        MechanicProfile profile = entity.getMechanicProfile();
        if (user == null && profile != null) {
            user = profile.getUser();
        }
        String mechanicName = null;
        if (profile != null && profile.getFullName() != null && !profile.getFullName().isBlank()) {
            mechanicName = profile.getFullName().trim();
        } else if (user != null) {
            mechanicName = user.getFullName();
        }
        String mechanicPhone = user != null ? user.getPhone() : null;
        return AttestationApplicationDTO.builder()
                .id(entity.getApplicationId())
                .userId(user != null ? user.getUserId() : null)
                .mechanicProfileId(profile != null ? profile.getProfileId() : null)
                .clubId(entity.getClub() != null ? entity.getClub().getClubId() : null)
                .mechanicName(mechanicName)
                .mechanicPhone(mechanicPhone)
                .status(AttestationDecisionStatus.fromEntity(entity.getStatus()))
                .comment(entity.getComment())
                .requestedGrade(entity.getRequestedGrade())
                .submittedAt(entity.getSubmittedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private User resolveActiveUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new IllegalStateException("User must be active to submit attestation");
        }
        if (user.getMechanicProfile() == null) {
            throw new IllegalStateException("User must have mechanic profile to submit attestation");
        }
        return user;
    }

    private MechanicProfile resolveMechanic(Long mechanicProfileId) {
        if (mechanicProfileId == null) {
            return null;
        }
        MechanicProfile profile = mechanicProfileRepository.findById(mechanicProfileId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic profile not found: " + mechanicProfileId));
        if (Boolean.FALSE.equals(profile.getUser().getIsActive())) {
            throw new IllegalStateException("Mechanic profile owner must be active");
        }
        return profile;
    }

    private BowlingClub resolveClub(Long clubId) {
        if (clubId == null) {
            return null;
        }
        return bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found: " + clubId));
    }

    private void validateSubmission(AttestationApplicationDTO dto) {
        if (dto == null) {
            throw new IllegalArgumentException("Application payload is required");
        }
        if (dto.getUserId() == null) {
            throw new IllegalArgumentException("User id is required");
        }
        if (dto.getMechanicProfileId() == null) {
            throw new IllegalArgumentException("Mechanic profile id is required");
        }
        if (dto.getRequestedGrade() == null) {
            throw new IllegalArgumentException("Requested grade is required");
        }
        MechanicProfile mechanicProfile = resolveMechanic(dto.getMechanicProfileId());
        if (!Objects.equals(mechanicProfile.getUser().getUserId(), dto.getUserId())) {
            throw new IllegalArgumentException("Mechanic profile must belong to the user");
        }

        if (dto.getClubId() != null && java.util.Optional.ofNullable(mechanicProfile.getClubs())
                .orElse(List.of())
                .stream()
                .map(BowlingClub::getClubId)
                .noneMatch(id -> Objects.equals(id, dto.getClubId()))) {
            throw new IllegalArgumentException("Mechanic must belong to the specified club");
        }
    }

    private void markApproved(AttestationApplication application, ru.bowling.bowlingapp.Entity.enums.MechanicGrade approvedGrade) {
        application.setStatus(AttestationStatus.APPROVED);
        ru.bowling.bowlingapp.Entity.enums.MechanicGrade resolvedGrade = approvedGrade != null
                ? approvedGrade
                : application.getRequestedGrade();
        application.setRequestedGrade(resolvedGrade);

        MechanicProfile profile = application.getMechanicProfile();
        if (profile != null) {
            profile.setIsDataVerified(true);
            profile.setVerificationDate(java.time.LocalDate.now());
            profile.setIsCertified(true);
            profile.setCertifiedGrade(resolvedGrade);
            profile.setUpdatedAt(java.time.LocalDate.now());
            mechanicProfileRepository.save(profile);
        }
    }
}
