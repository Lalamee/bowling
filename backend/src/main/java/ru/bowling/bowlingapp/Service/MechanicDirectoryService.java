package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.MechanicCertificationDTO;
import ru.bowling.bowlingapp.DTO.MechanicDirectoryDetailDTO;
import ru.bowling.bowlingapp.DTO.MechanicDirectorySummaryDTO;
import ru.bowling.bowlingapp.DTO.MechanicWorkHistoryDTO;
import ru.bowling.bowlingapp.DTO.SpecialistCardDTO;
import ru.bowling.bowlingapp.Entity.AttestationApplication;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MechanicCertification;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.MechanicWorkHistory;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;
import ru.bowling.bowlingapp.Repository.AttestationApplicationRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class MechanicDirectoryService {

    private final MechanicProfileRepository mechanicProfileRepository;
    private final AttestationApplicationRepository attestationApplicationRepository;

    public List<MechanicDirectorySummaryDTO> searchMechanics(String query, String region, String certification) {
        List<MechanicProfile> profiles = mechanicProfileRepository.findAllWithUserAndClubs();

        String loweredQuery = normalize(query);
        String loweredRegion = normalize(region);
        String loweredCertification = normalize(certification);

        return profiles.stream()
                .filter(Objects::nonNull)
                .filter(profile -> matchesQuery(profile, loweredQuery))
                .filter(profile -> matchesRegion(profile, loweredRegion))
                .filter(profile -> matchesCertification(profile, loweredCertification))
                .map(this::toSummary)
                .sorted(Comparator.comparing(MechanicDirectorySummaryDTO::getFullName, Comparator.nullsLast(String::compareToIgnoreCase)))
                .collect(Collectors.toList());
    }

    public List<SpecialistCardDTO> getSpecialistBase(String region,
                                                    Integer specializationId,
                                                    MechanicGrade grade,
                                                    Double minRating) {
        List<MechanicProfile> profiles = mechanicProfileRepository.findAllWithUserAndClubs();
        var approvedGrades = attestationApplicationRepository.findByStatus(AttestationStatus.APPROVED)
                .stream()
                .filter(app -> app.getMechanicProfile() != null && app.getMechanicProfile().getProfileId() != null)
                .collect(Collectors.toMap(app -> app.getMechanicProfile().getProfileId(),
                        Function.identity(),
                        this::selectLatestByUpdate))
                .entrySet()
                .stream()
                .collect(Collectors.toMap(
                        java.util.Map.Entry::getKey,
                        entry -> entry.getValue().getRequestedGrade()
                ));

        String normalizedRegion = normalize(region);

        return profiles.stream()
                .filter(profile -> Boolean.TRUE.equals(profile.getIsDataVerified()))
                .filter(profile -> approvedGrades.containsKey(profile.getProfileId()))
                .filter(profile -> specializationId == null || Objects.equals(profile.getSpecializationId(), specializationId))
                .filter(profile -> matchesRegion(profile, normalizedRegion))
                .filter(profile -> minRating == null || (profile.getRating() != null && profile.getRating() >= minRating))
                .filter(profile -> grade == null || grade.equals(approvedGrades.get(profile.getProfileId())))
                .map(profile -> toSpecialistCard(profile, approvedGrades.get(profile.getProfileId())))
                .sorted(Comparator.comparing(SpecialistCardDTO::getFullName, Comparator.nullsLast(String::compareToIgnoreCase)))
                .collect(Collectors.toList());
    }

    public MechanicDirectoryDetailDTO getMechanicDetail(Long profileId) {
        MechanicProfile profile = mechanicProfileRepository.findDetailedById(profileId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic profile not found"));

        List<MechanicDirectorySummaryDTO> clubs = Optional.ofNullable(profile.getClubs())
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(this::toClubSummary)
                .collect(Collectors.toList());

        User user = profile.getUser();

        return MechanicDirectoryDetailDTO.builder()
                .profileId(profile.getProfileId())
                .userId(user != null ? user.getUserId() : null)
                .fullName(profile.getFullName())
                .contactPhone(user != null ? user.getPhone() : null)
                .specialization(profile.getSkills())
                .rating(profile.getRating())
                .status(resolveStatus(profile))
                .region(resolveRegion(profile))
                .certifications(resolveCertificationDtos(profile))
                .totalExperienceYears(profile.getTotalExperienceYears())
                .bowlingExperienceYears(profile.getBowlingExperienceYears())
                .isEntrepreneur(profile.getIsEntrepreneur())
                .isDataVerified(profile.getIsDataVerified())
                .verificationDate(profile.getVerificationDate())
                .relatedClubs(clubs)
                .workHistory(resolveWorkHistory(profile))
                .attestationStatus(resolveAttestationStatus(profile))
                .build();
    }

    private boolean matchesQuery(MechanicProfile profile, String loweredQuery) {
        if (loweredQuery == null) {
            return true;
        }
        return Optional.ofNullable(profile.getFullName())
                .map(name -> name.toLowerCase(Locale.ROOT))
                .map(name -> name.contains(loweredQuery))
                .orElse(false)
                || Optional.ofNullable(profile.getSkills())
                .map(skills -> skills.toLowerCase(Locale.ROOT))
                .map(skills -> skills.contains(loweredQuery))
                .orElse(false);
    }

    private boolean matchesRegion(MechanicProfile profile, String loweredRegion) {
        if (loweredRegion == null) {
            return true;
        }
        String region = resolveRegion(profile);
        if (region == null) {
            return true;
        }
        return region.toLowerCase(Locale.ROOT).contains(loweredRegion);
    }

    private boolean matchesCertification(MechanicProfile profile, String loweredCertification) {
        if (loweredCertification == null) {
            return true;
        }
        List<String> certifications = resolveCertificationTokens(profile);
        if (certifications.isEmpty()) {
            return true;
        }
        return certifications.stream()
                .map(value -> value.toLowerCase(Locale.ROOT))
                .anyMatch(value -> value.contains(loweredCertification));
    }

    private MechanicDirectorySummaryDTO toSummary(MechanicProfile profile) {
        List<String> clubs = Optional.ofNullable(profile.getClubs())
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(BowlingClub::getName)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        return MechanicDirectorySummaryDTO.builder()
                .profileId(profile.getProfileId())
                .fullName(profile.getFullName())
                .specialization(profile.getSkills())
                .rating(profile.getRating())
                .status(resolveStatus(profile))
                .region(resolveRegion(profile))
                .clubs(clubs)
                .certifications(resolveCertificationDtos(profile))
                .build();
    }

    private SpecialistCardDTO toSpecialistCard(MechanicProfile profile, MechanicGrade grade) {
        List<String> clubs = Optional.ofNullable(profile.getClubs())
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(BowlingClub::getName)
                .filter(Objects::nonNull)
                .toList();

        User user = profile.getUser();
        return SpecialistCardDTO.builder()
                .profileId(profile.getProfileId())
                .userId(user != null ? user.getUserId() : null)
                .fullName(profile.getFullName())
                .region(resolveRegion(profile))
                .specializationId(profile.getSpecializationId())
                .skills(profile.getSkills())
                .advantages(profile.getAdvantages())
                .totalExperienceYears(profile.getTotalExperienceYears())
                .bowlingExperienceYears(profile.getBowlingExperienceYears())
                .isEntrepreneur(profile.getIsEntrepreneur())
                .rating(profile.getRating())
                .attestedGrade(grade)
                .accountType(user != null && user.getAccountType() != null ? user.getAccountType().getName() : null)
                .verificationDate(profile.getVerificationDate())
                .clubs(clubs)
                .build();
    }

    private MechanicDirectorySummaryDTO toClubSummary(BowlingClub club) {
        return MechanicDirectorySummaryDTO.builder()
                .profileId(null)
                .fullName(club.getName())
                .specialization(null)
                .rating(null)
                .status("CLUB")
                .region(resolveClubRegion(club))
                .clubs(null)
                .certifications(null)
                .build();
    }

    private String resolveStatus(MechanicProfile profile) {
        if (profile.getClubs() != null && !profile.getClubs().isEmpty()) {
            return "CLUB_MECHANIC";
        }
        return "FREE_AGENT";
    }

    private String resolveRegion(MechanicProfile profile) {
        if (profile == null) {
            return null;
        }

        String profileRegion = normalizeRegion(profile.getRegion());
        if (profileRegion != null) {
            return profileRegion;
        }

        String fromClubAddress = Optional.ofNullable(profile.getClubs())
                .orElse(List.of())
                .stream()
                .map(this::resolveClubRegion)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);
        if (fromClubAddress != null) {
            return fromClubAddress;
        }

        String fromHistory = Optional.ofNullable(profile.getWorkHistoryEntries())
                .orElse(List.of())
                .stream()
                .map(MechanicWorkHistory::getOrganization)
                .map(this::normalizeRegion)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);
        if (fromHistory != null) {
            return fromHistory;
        }
        return null;
    }

    private String resolveClubRegion(BowlingClub club) {
        if (club == null || club.getAddress() == null) {
            return null;
        }
        return extractRegionFragment(club.getAddress());
    }

    private String extractRegionFragment(String rawAddress) {
        String trimmed = rawAddress.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        int commaIndex = trimmed.indexOf(',');
        return commaIndex > 0 ? trimmed.substring(0, commaIndex).trim() : trimmed;
    }

    private String normalizeRegion(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return extractRegionFragment(trimmed);
    }

    private List<MechanicCertificationDTO> resolveCertificationDtos(MechanicProfile profile) {
        return Optional.ofNullable(profile)
                .map(MechanicProfile::getCertifications)
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(this::toCertificationDto)
                .collect(Collectors.toList());
    }

    private MechanicCertificationDTO toCertificationDto(MechanicCertification certification) {
        if (certification == null) {
            return null;
        }
        return MechanicCertificationDTO.builder()
                .certificationId(certification.getCertificationId())
                .title(certification.getTitle())
                .issuer(certification.getIssuer())
                .issueDate(certification.getIssueDate())
                .expirationDate(certification.getExpirationDate())
                .credentialUrl(certification.getCredentialUrl())
                .description(certification.getDescription())
                .build();
    }

    private List<String> resolveCertificationTokens(MechanicProfile profile) {
        return resolveCertificationDtos(profile).stream()
                .flatMap(dto -> Stream.of(dto.getTitle(), dto.getIssuer()))
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(token -> !token.isEmpty())
                .collect(Collectors.toList());
    }

    private List<MechanicWorkHistoryDTO> resolveWorkHistory(MechanicProfile profile) {
        return Optional.ofNullable(profile)
                .map(MechanicProfile::getWorkHistoryEntries)
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(this::toWorkHistoryDto)
                .collect(Collectors.toList());
    }

    private MechanicWorkHistoryDTO toWorkHistoryDto(MechanicWorkHistory history) {
        if (history == null) {
            return null;
        }
        return MechanicWorkHistoryDTO.builder()
                .historyId(history.getHistoryId())
                .organization(history.getOrganization())
                .position(history.getPosition())
                .startDate(history.getStartDate())
                .endDate(history.getEndDate())
                .description(history.getDescription())
                .build();
    }

    private AttestationStatus resolveAttestationStatus(MechanicProfile profile) {
        if (profile == null || profile.getProfileId() == null) {
            return AttestationStatus.NEW;
        }
        return attestationApplicationRepository
                .findFirstByMechanicProfile_ProfileIdOrderByUpdatedAtDesc(profile.getProfileId())
                .map(AttestationApplication::getStatus)
                .orElseGet(() -> Boolean.TRUE.equals(profile.getIsDataVerified())
                        ? AttestationStatus.APPROVED
                        : AttestationStatus.NEW);
    }

    private AttestationApplication selectLatestByUpdate(AttestationApplication left, AttestationApplication right) {
        if (left.getUpdatedAt() == null) {
            return right;
        }
        if (right.getUpdatedAt() == null) {
            return left;
        }
        return left.getUpdatedAt().isAfter(right.getUpdatedAt()) ? left : right;
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed.toLowerCase(Locale.ROOT);
    }
}

