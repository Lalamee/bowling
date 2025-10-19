package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubInvitationRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

@Service
@RequiredArgsConstructor
public class InvitationService {

    private final ClubInvitationRepository invitationRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final UserRepository userRepository;

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
    public void acceptInvitation(Long invitationId) {
        ClubInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));

        invitation.setStatus("ACCEPTED");

        User mechanicUser = invitation.getMechanic();
        MechanicProfile mechanicProfile = mechanicUser.getMechanicProfile();
        BowlingClub club = (BowlingClub) invitation.getClub();

        mechanicProfile.getClubs().add(club);

        invitationRepository.save(invitation);
    }

    @Transactional
    public void rejectInvitation(Long invitationId) {
        ClubInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));
        invitation.setStatus("REJECTED");
        invitationRepository.save(invitation);
    }
}
