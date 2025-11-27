package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class UserClubAccessService {

    private final UserRepository userRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final OwnerProfileRepository ownerProfileRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final ClubInvitationRepository clubInvitationRepository;

    @Transactional(readOnly = true)
    public List<Long> resolveAccessibleClubIds(Long userId) {
        User user = userId != null ? userRepository.findById(userId).orElse(null) : null;
        return resolveAccessibleClubIds(user);
    }

    @Transactional(readOnly = true)
    public List<Long> resolveAccessibleClubIds(User user) {
        if (user == null || user.getRole() == null || user.getRole().getName() == null) {
            return List.of();
        }

        RoleName roleName = RoleName.from(user.getRole().getName());
        if (roleName == RoleName.ADMIN) {
            return bowlingClubRepository.findAll().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .toList();
        }

        Set<Long> clubIds = new LinkedHashSet<>();

        MechanicProfile mechanicProfile = mechanicProfileRepository.findByUser_UserId(user.getUserId()).orElse(null);
        OwnerProfile ownerProfile = ownerProfileRepository.findByUser_UserId(user.getUserId()).orElse(null);
        ManagerProfile managerProfile = managerProfileRepository.findByUser_UserId(user.getUserId()).orElse(null);

        if (mechanicProfile != null && roleName == RoleName.MECHANIC) {
            AccountTypeName accountType = resolveAccountType(user);
            if (accountType == AccountTypeName.INDIVIDUAL) {
                clubStaffRepository.findByUserUserIdAndIsActiveTrue(user.getUserId())
                        .forEach(staff -> clubIds.add(staff.getClub().getClubId()));
            } else if (accountType == AccountTypeName.FREE_MECHANIC_BASIC
                    || accountType == AccountTypeName.FREE_MECHANIC_PREMIUM) {
                clubInvitationRepository.findByMechanic_UserIdAndStatus(user.getUserId(), "ACCEPTED")
                        .stream()
                        .map(ClubInvitation::getClub)
                        .filter(Objects::nonNull)
                        .map(BowlingClub::getClubId)
                        .forEach(clubIds::add);
            }
        }

        if (managerProfile != null && managerProfile.getClub() != null
                && (roleName == RoleName.HEAD_MECHANIC || roleName == RoleName.MECHANIC)) {
            clubIds.add(managerProfile.getClub().getClubId());
        }

        if (ownerProfile != null && ownerProfile.getClubs() != null && roleName == RoleName.CLUB_OWNER) {
            ownerProfile.getClubs().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .forEach(clubIds::add);
        }

        return clubIds.stream().toList();
    }

    @Transactional(readOnly = true)
    public boolean hasClubAccess(User user, Long clubId) {
        if (clubId == null) {
            return false;
        }
        return resolveAccessibleClubIds(user).contains(clubId);
    }

    private AccountTypeName resolveAccountType(User user) {
        if (user == null || user.getAccountType() == null || user.getAccountType().getName() == null) {
            return AccountTypeName.INDIVIDUAL;
        }
        return AccountTypeName.from(user.getAccountType().getName());
    }

    @Transactional(readOnly = true)
    public boolean isPremiumFreeMechanic(User user) {
        return resolveAccountType(user) == AccountTypeName.FREE_MECHANIC_PREMIUM;
    }
}
