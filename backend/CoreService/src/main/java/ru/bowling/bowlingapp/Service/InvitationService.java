package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class InvitationService {

    private final ClubInvitationRepository invitationRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final UserRepository userRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final OwnerProfileRepository ownerProfileRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final MechanicProfileRepository mechanicProfileRepository;

    @Transactional
    public void inviteMechanic(Long clubId, Long mechanicId) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));
        User mechanic = userRepository.findById(mechanicId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic not found"));

        ClubInvitation invitation = new ClubInvitation();
        invitation.setClub(club);
        invitation.setMechanic(mechanic);
        invitation.setStatus("PENDING");
        invitationRepository.save(invitation);
    }

    @Transactional
    public void ownerApproveInvitation(Long invitationId, String ownerPhone) {
        ClubInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));

        if (!"OWNER_REVIEW".equalsIgnoreCase(invitation.getStatus())) {
            throw new IllegalStateException("Invitation is not waiting for owner review");
        }

        User ownerUser = userRepository.findByPhone(ownerPhone)
                .orElseThrow(() -> new IllegalArgumentException("Owner not found"));
        OwnerProfile ownerProfile = ownerProfileRepository.findByUser_UserId(ownerUser.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("Owner profile not found"));

        boolean clubOwned = ownerProfile.getClubs() != null && ownerProfile.getClubs().stream()
                .anyMatch(c -> Objects.equals(c.getClubId(), invitation.getClub().getClubId()));
        if (!clubOwned) {
            throw new IllegalArgumentException("Owner does not manage this club");
        }

        invitation.setStatus("ACCEPTED");
        activateMechanicInClub(invitation.getMechanic(), invitation.getClub());
        invitationRepository.save(invitation);
    }

    @Transactional
    public void acceptInvitation(Long invitationId) {
        ClubInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));

        if (!"PENDING".equalsIgnoreCase(invitation.getStatus())) {
            throw new IllegalStateException("Invitation is not pending mechanic confirmation");
        }

        invitation.setStatus("ACCEPTED");
        activateMechanicInClub(invitation.getMechanic(), invitation.getClub());
        invitationRepository.save(invitation);
    }

    @Transactional
    public void rejectInvitation(Long invitationId) {
        ClubInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));
        invitation.setStatus("REJECTED");
        invitationRepository.save(invitation);
    }

    private void activateMechanicInClub(User mechanicUser, BowlingClub club) {
        MechanicProfile mechanicProfile = mechanicUser.getMechanicProfile();
        if (mechanicProfile == null) {
            throw new IllegalStateException("Mechanic profile not found");
        }

        AccountTypeName accountType = mechanicUser.getAccountType() != null
                ? AccountTypeName.from(mechanicUser.getAccountType().getName())
                : AccountTypeName.INDIVIDUAL;

        if (accountType == AccountTypeName.FREE_MECHANIC_BASIC || accountType == AccountTypeName.FREE_MECHANIC_PREMIUM) {
            AccountType clubMechanicType = accountTypeRepository
                    .findFirstByNameIgnoreCaseOrderByAccountTypeIdAsc(AccountTypeName.INDIVIDUAL.name())
                    .orElseThrow(() -> new IllegalStateException("Account type not configured: " + AccountTypeName.INDIVIDUAL));
            mechanicUser.setAccountType(clubMechanicType);
        }

        if (mechanicProfile.getClubs() == null) {
            mechanicProfile.setClubs(new ArrayList<>());
        }
        if (mechanicProfile.getClubs().stream().noneMatch(c -> Objects.equals(c.getClubId(), club.getClubId()))) {
            mechanicProfile.getClubs().add(club);
        }

        ClubStaff staff = clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, mechanicUser)
                .orElseGet(() -> ClubStaff.builder()
                        .club(club)
                        .user(mechanicUser)
                        .assignedAt(LocalDateTime.now())
                        .build());
        staff.setRole(mechanicUser.getRole());
        staff.setIsActive(Boolean.TRUE);
        staff.setInfoAccessRestricted(Boolean.FALSE);

        mechanicProfileRepository.save(mechanicProfile);
        userRepository.save(mechanicUser);
        clubStaffRepository.save(staff);
    }
}
