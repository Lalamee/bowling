package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.MechanicDirectoryDetailDTO;
import ru.bowling.bowlingapp.DTO.MechanicDirectorySummaryDTO;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MechanicDirectoryService {

    private final MechanicProfileRepository mechanicProfileRepository;

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

    public MechanicDirectoryDetailDTO getMechanicDetail(Long profileId) {
        MechanicProfile profile = mechanicProfileRepository.findById(profileId)
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
                .region(null) // TODO: подтянуть регион из анкеты, когда поле появится
                .certifications(new ArrayList<>()) // TODO: заменить на реальные сертификаты из БД
                .totalExperienceYears(profile.getTotalExperienceYears())
                .bowlingExperienceYears(profile.getBowlingExperienceYears())
                .isEntrepreneur(profile.getIsEntrepreneur())
                .isDataVerified(profile.getIsDataVerified())
                .verificationDate(profile.getVerificationDate())
                .relatedClubs(clubs)
                .workPlaces(profile.getWorkPlaces())
                .workPeriods(profile.getWorkPeriods())
                .attestationStatus("TODO: добавить статус аттестации после появления модели")
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
        // TODO: заменить на фильтр по региону из анкеты, когда поле появится в БД
        return true;
    }

    private boolean matchesCertification(MechanicProfile profile, String loweredCertification) {
        if (loweredCertification == null) {
            return true;
        }
        // TODO: фильтр по сертификатам, когда будет модель сертификации
        return true;
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
                .region(null) // TODO: подтянуть регион из анкеты, когда поле появится
                .clubs(clubs)
                .certifications(List.of()) // TODO: заменить на реальные данные из БД
                .build();
    }

    private MechanicDirectorySummaryDTO toClubSummary(BowlingClub club) {
        return MechanicDirectorySummaryDTO.builder()
                .profileId(null)
                .fullName(club.getName())
                .specialization(null)
                .rating(null)
                .status("CLUB")
                .region(null) // TODO: использовать адрес/регион клуба, когда появится структура
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

    private String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed.toLowerCase(Locale.ROOT);
    }
}

