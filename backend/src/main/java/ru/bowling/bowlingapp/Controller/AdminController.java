package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Service.AdminCabinetService;
import ru.bowling.bowlingapp.Service.AdminService;
import ru.bowling.bowlingapp.Service.FreeMechanicApplicationService;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final AdminCabinetService adminCabinetService;
    private final FreeMechanicApplicationService freeMechanicApplicationService;

    @GetMapping("/mechanics")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<AdminMechanicListResponseDTO> getMechanicsOverview(Authentication authentication) {
        return ResponseEntity.ok(adminService.getMechanicsOverview(authentication != null ? authentication.getName() : null));
    }

    @GetMapping("/registrations")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdminRegistrationApplicationDTO>> listRegistrations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        return ResponseEntity.ok(adminCabinetService.listRegistrationApplications(page, size));
    }

    @PostMapping("/registrations/{userId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminRegistrationApplicationDTO> approveRegistration(@PathVariable Long userId) {
        return ResponseEntity.ok(adminCabinetService.approveRegistration(userId));
    }

    @PostMapping("/registrations/{userId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminRegistrationApplicationDTO> rejectRegistration(@PathVariable Long userId,
                                                                              @RequestBody(required = false) String reason) {
        return ResponseEntity.ok(adminCabinetService.rejectRegistration(userId, reason));
    }

    @GetMapping("/free-mechanics/applications")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<List<FreeMechanicApplicationResponseDTO>> listFreeMechanicApplications() {
        return ResponseEntity.ok(freeMechanicApplicationService.listApplications());
    }

    @PostMapping("/free-mechanics/applications/{applicationId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FreeMechanicApplicationResponseDTO> approveFreeMechanic(
            @PathVariable Long applicationId,
            @RequestBody MechanicApplicationDecisionDTO decision
    ) {
        return ResponseEntity.ok(freeMechanicApplicationService.approve(applicationId, decision));
    }

    @PostMapping("/free-mechanics/applications/{applicationId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FreeMechanicApplicationResponseDTO> rejectFreeMechanic(
            @PathVariable Long applicationId,
            @RequestBody MechanicApplicationDecisionDTO decision
    ) {
        return ResponseEntity.ok(freeMechanicApplicationService.reject(applicationId, decision != null ? decision.getComment() : null));
    }

    @PatchMapping("/free-mechanics/{userId}/account")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminRegistrationApplicationDTO> updateFreeMechanicAccount(
            @PathVariable Long userId,
            @RequestBody AdminAccountUpdateDTO update
    ) {
        return ResponseEntity.ok(adminCabinetService.updateFreeMechanicAccount(userId, update));
    }

    @PostMapping("/free-mechanics/{userId}/assign-club")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<AdminRegistrationApplicationDTO> assignFreeMechanicToClub(
            @PathVariable Long userId,
            @RequestBody(required = false) FreeMechanicClubAssignRequestDTO request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(adminCabinetService.assignFreeMechanicToClub(
                userId,
                request,
                authentication != null ? authentication.getName() : null
        ));
    }

    @PatchMapping("/mechanics/{userId}/account")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminRegistrationApplicationDTO> convertMechanicAccount(
            @PathVariable Long userId,
            @RequestBody AdminMechanicAccountChangeDTO change
    ) {
        return ResponseEntity.ok(adminCabinetService.convertMechanicAccount(userId, change));
    }

    @PatchMapping("/mechanics/{profileId}/clubs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminRegistrationApplicationDTO> changeMechanicClub(
            @PathVariable Long profileId,
            @RequestBody MechanicClubLinkRequestDTO request
    ) {
        return ResponseEntity.ok(adminCabinetService.changeMechanicClubLink(profileId, request));
    }

    @GetMapping("/attestations")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AttestationApplicationDTO>> listAttestations() {
        return ResponseEntity.ok(adminCabinetService.listAttestationApplications());
    }

    @PutMapping("/attestations/{id}/decision")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AttestationApplicationDTO> decideAttestation(
            @PathVariable Long id,
            @RequestBody AttestationDecisionDTO decision
    ) {
        return ResponseEntity.ok(adminCabinetService.decideAttestation(id, decision));
    }

    @GetMapping("/supplier-complaints")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdminComplaintDTO>> listComplaints() {
        return ResponseEntity.ok(adminCabinetService.listSupplierComplaints());
    }

    @PatchMapping("/supplier-complaints/{reviewId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminComplaintDTO> updateComplaint(
            @PathVariable Long reviewId,
            @RequestParam(required = false) SupplierComplaintStatus status,
            @RequestParam(required = false) Boolean resolved,
            @RequestParam(required = false) String notes
    ) {
        return ResponseEntity.ok(adminCabinetService.updateComplaintStatus(reviewId, status, resolved, notes));
    }

    @GetMapping("/help-requests")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdminHelpRequestDTO>> listHelpRequests() {
        return ResponseEntity.ok(adminCabinetService.listHelpRequests());
    }

    @GetMapping("/staff/status-requests")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<List<AdminMechanicStatusChangeDTO>> listMechanicStatusChanges(Authentication authentication) {
        return ResponseEntity.ok(adminCabinetService.listMechanicStatusChanges(authentication != null ? authentication.getName() : null));
    }

    @PatchMapping("/staff/{staffId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminMechanicStatusChangeDTO> updateMechanicStatus(
            @PathVariable Long staffId,
            @RequestBody AdminStaffStatusUpdateDTO update
    ) {
        return ResponseEntity.ok(adminCabinetService.updateMechanicStaffStatus(staffId, update));
    }

    @GetMapping("/appeals")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdminAppealDTO>> listAppeals() {
        return ResponseEntity.ok(adminCabinetService.listAdministrativeAppeals());
    }

    @PostMapping("/appeals/{appealId}/reply")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<NotificationEvent> replyAppeal(
            @PathVariable String appealId,
            @RequestBody AdminAppealReplyDTO request
    ) {
        return ResponseEntity.ok(adminCabinetService.replyToAppeal(appealId, request));
    }

    @PutMapping("/users/{userId}/verify")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> verifyUser(@PathVariable Long userId) {
        adminService.verifyUser(userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/users/{userId}/activate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> activateUser(@PathVariable Long userId) {
        adminService.setUserActiveStatus(userId, true);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/users/{userId}/deactivate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deactivateUser(@PathVariable Long userId) {
        adminService.setUserActiveStatus(userId, false);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/users/{userId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> rejectRegistration(@PathVariable Long userId) {
        adminService.rejectRegistration(userId);
        return ResponseEntity.ok().build();
    }
}
