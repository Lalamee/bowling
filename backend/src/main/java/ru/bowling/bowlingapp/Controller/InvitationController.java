package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.Service.InvitationService;

@RestController
@RequestMapping("/api/invitations")
@RequiredArgsConstructor
public class InvitationController {

    private final InvitationService invitationService;

    @PostMapping("/club/{clubId}/mechanic/{mechanicId}")
    @PreAuthorize("hasAnyRole('OWNER', 'CLUB_OWNER')")
    public ResponseEntity<?> inviteMechanic(@PathVariable Long clubId, @PathVariable Long mechanicId) {
        invitationService.inviteMechanic(clubId, mechanicId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{invitationId}/owner-approve")
    @PreAuthorize("hasAnyRole('OWNER', 'CLUB_OWNER')")
    public ResponseEntity<?> ownerApproveInvitation(@PathVariable Long invitationId, Authentication authentication) {
        invitationService.ownerApproveInvitation(invitationId, authentication != null ? authentication.getName() : null);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{invitationId}/accept")
    @PreAuthorize("hasRole('MECHANIC')")
    public ResponseEntity<?> acceptInvitation(@PathVariable Long invitationId) {
        invitationService.acceptInvitation(invitationId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{invitationId}/reject")
    @PreAuthorize("hasRole('MECHANIC')")
    public ResponseEntity<?> rejectInvitation(@PathVariable Long invitationId) {
        invitationService.rejectInvitation(invitationId);
        return ResponseEntity.ok().build();
    }
}
