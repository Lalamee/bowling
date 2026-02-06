package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.AdminMechanicClubDTO;
import ru.bowling.bowlingapp.DTO.AdminMechanicListResponseDTO;
import ru.bowling.bowlingapp.DTO.AdminMechanicSummaryDTO;
import ru.bowling.bowlingapp.DTO.AdminPendingMechanicDTO;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.OwnerProfileRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final OwnerProfileRepository ownerProfileRepository;

    @Transactional
    public void verifyUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setIsVerified(true);
        user.setIsActive(true);
        if (user.getMechanicProfile() != null) {
            MechanicProfile mechanicProfile = user.getMechanicProfile();
            mechanicProfile.setIsDataVerified(true);
            mechanicProfileRepository.save(mechanicProfile);

            if (mechanicProfile.getClubs() != null) {
                for (BowlingClub club : mechanicProfile.getClubs()) {
                    if (club == null) {
                        continue;
                    }
                    clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, user)
                            .ifPresent(staff -> {
                                if (!Boolean.TRUE.equals(staff.getIsActive())) {
                                    staff.setIsActive(true);
                                    clubStaffRepository.save(staff);
                                }
                            });
                }
            }
        }
        if (user.getOwnerProfile() != null) {
            user.getOwnerProfile().setIsDataVerified(true);
        }
        userRepository.save(user);
    }

    @Transactional
    public void setUserActiveStatus(Long userId, boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setIsActive(isActive);
        userRepository.save(user);
    }

    @Transactional
    public void rejectRegistration(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found");
        }
        // Простое удаление пользователя. В реальной системе здесь может быть логирование, уведомление и т.д.
        userRepository.deleteById(userId);
    }

    @Transactional(readOnly = true)
    public AdminMechanicListResponseDTO getMechanicsOverview() {
        return getMechanicsOverview(null);
    }

    @Transactional(readOnly = true)
    public AdminMechanicListResponseDTO getMechanicsOverview(String actorPhone) {
        Set<Long> allowedClubIds = resolveAllowedClubIds(actorPhone);
        List<MechanicProfile> profiles = mechanicProfileRepository.findAllWithUserAndClubs();

        List<AdminPendingMechanicDTO> pending = new ArrayList<>();
        Map<Long, ClubMechanicsAggregate> clubAggregates = new LinkedHashMap<>();

        for (MechanicProfile profile : profiles) {
            if (profile == null) {
                continue;
            }
            if (isPending(profile)) {
                AdminPendingMechanicDTO pendingDto = mapPending(profile);
                if (allowedClubIds == null || (pendingDto.getRequestedClubId() != null && allowedClubIds.contains(pendingDto.getRequestedClubId()))) {
                    pending.add(pendingDto);
                }
                continue;
            }

            if (profile.getClubs() == null || profile.getClubs().isEmpty()) {
                continue;
            }

            AdminMechanicSummaryDTO mechanicDto = mapSummary(profile);
            for (BowlingClub club : profile.getClubs()) {
                if (club == null || club.getClubId() == null) {
                    continue;
                }
                if (allowedClubIds != null && !allowedClubIds.contains(club.getClubId())) {
                    continue;
                }
                ClubMechanicsAggregate aggregate = clubAggregates.computeIfAbsent(
                        club.getClubId(),
                        id -> new ClubMechanicsAggregate(club)
                );
                aggregate.mechanics.add(mechanicDto);
            }
        }

        pending.sort(Comparator
                .comparing((AdminPendingMechanicDTO dto) -> parseDate(dto.getCreatedAt()), Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(AdminPendingMechanicDTO::getUserId, Comparator.nullsLast(Comparator.naturalOrder()))
        );

        List<AdminMechanicClubDTO> clubDtos = new ArrayList<>();
        for (ClubMechanicsAggregate aggregate : clubAggregates.values()) {
            aggregate.mechanics.sort(Comparator
                    .comparing(AdminMechanicSummaryDTO::getFullName, Comparator.nullsLast(String::compareToIgnoreCase))
                    .thenComparing(AdminMechanicSummaryDTO::getUserId, Comparator.nullsLast(Comparator.naturalOrder()))
            );

            BowlingClub club = aggregate.club;
            clubDtos.add(AdminMechanicClubDTO.builder()
                    .clubId(club.getClubId())
                    .clubName(club.getName())
                    .address(club.getAddress())
                    .contactPhone(club.getContactPhone())
                    .contactEmail(club.getContactEmail())
                    .mechanics(new ArrayList<>(aggregate.mechanics))
                    .build());
        }

        return AdminMechanicListResponseDTO.builder()
                .pending(pending)
                .clubs(clubDtos)
                .build();
    }

    private Set<Long> resolveAllowedClubIds(String actorPhone) {
        if (actorPhone == null || actorPhone.isBlank()) {
            return null;
        }
        User actor = userRepository.findByPhone(actorPhone).orElse(null);
        if (actor == null || actor.getRole() == null) {
            return null;
        }
        RoleName roleName = RoleName.from(actor.getRole().getName());
        if (roleName == RoleName.ADMIN) {
            return null;
        }
        if (roleName != RoleName.CLUB_OWNER) {
            return Set.of();
        }
        OwnerProfile ownerProfile = ownerProfileRepository.findByUser_UserId(actor.getUserId()).orElse(null);
        if (ownerProfile == null || ownerProfile.getClubs() == null) {
            return Set.of();
        }
        return ownerProfile.getClubs().stream()
                .map(BowlingClub::getClubId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    private boolean isPending(MechanicProfile profile) {
        Boolean dataVerified = profile.getIsDataVerified();
        if (dataVerified == null || !dataVerified) {
            return true;
        }
        User user = profile.getUser();
        if (user == null) {
            return true;
        }
        Boolean verified = user.getIsVerified();
        return verified == null || !verified;
    }

    private AdminMechanicSummaryDTO mapSummary(MechanicProfile profile) {
        User user = profile.getUser();
        return AdminMechanicSummaryDTO.builder()
                .userId(user != null ? user.getUserId() : null)
                .profileId(profile.getProfileId())
                .fullName(resolveName(profile))
                .phone(user != null ? user.getPhone() : null)
                .isActive(user != null ? user.getIsActive() : null)
                .isVerified(user != null ? user.getIsVerified() : null)
                .isDataVerified(profile.getIsDataVerified())
                .build();
    }

    private AdminPendingMechanicDTO mapPending(MechanicProfile profile) {
        User user = profile.getUser();
        BowlingClub preferredClub = null;
        if (profile.getClubs() != null && !profile.getClubs().isEmpty()) {
            preferredClub = profile.getClubs().get(0);
        }

        return AdminPendingMechanicDTO.builder()
                .userId(user != null ? user.getUserId() : null)
                .profileId(profile.getProfileId())
                .fullName(resolveName(profile))
                .phone(user != null ? user.getPhone() : null)
                .isActive(user != null ? user.getIsActive() : null)
                .isVerified(user != null ? user.getIsVerified() : null)
                .isDataVerified(profile.getIsDataVerified())
                .requestedClubId(preferredClub != null ? preferredClub.getClubId() : null)
                .requestedClubName(preferredClub != null ? preferredClub.getName() : null)
                .requestedClubAddress(preferredClub != null ? preferredClub.getAddress() : null)
                .createdAt(profile.getCreatedAt() != null ? profile.getCreatedAt().toString() : null)
                .build();
    }

    private String resolveName(MechanicProfile profile) {
        if (profile.getFullName() != null && !profile.getFullName().trim().isEmpty()) {
            return profile.getFullName().trim();
        }
        User user = profile.getUser();
        if (user != null && user.getPhone() != null) {
            return user.getPhone();
        }
        return "Механик";
    }

    private LocalDate parseDate(String date) {
        if (date == null || date.isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(date);
        } catch (DateTimeParseException ex) {
            return null;
        }
    }

    private static class ClubMechanicsAggregate {
        private final BowlingClub club;
        private final List<AdminMechanicSummaryDTO> mechanics = new ArrayList<>();

        private ClubMechanicsAggregate(BowlingClub club) {
            this.club = club;
        }
    }
}
