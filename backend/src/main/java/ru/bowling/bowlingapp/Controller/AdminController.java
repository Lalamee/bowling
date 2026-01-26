package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.AdminAppealDTO;
import ru.bowling.bowlingapp.DTO.AdminMechanicAccountChangeDTO;
import ru.bowling.bowlingapp.DTO.AdminMechanicListResponseDTO;
import ru.bowling.bowlingapp.DTO.AdminMechanicStatusChangeDTO;
import ru.bowling.bowlingapp.DTO.AdminRegistrationApplicationDTO;
import ru.bowling.bowlingapp.DTO.AdminComplaintDTO;
import ru.bowling.bowlingapp.DTO.AdminAccountUpdateDTO;
import ru.bowling.bowlingapp.DTO.AdminHelpRequestDTO;
import ru.bowling.bowlingapp.DTO.AdminStaffStatusUpdateDTO;
import ru.bowling.bowlingapp.DTO.AdminAppealReplyDTO;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.DTO.AttestationDecisionDTO;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationResponseDTO;
import ru.bowling.bowlingapp.DTO.MechanicApplicationDecisionDTO;
import ru.bowling.bowlingapp.DTO.MechanicClubLinkRequestDTO;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Service.AdminService;
import ru.bowling.bowlingapp.Service.FreeMechanicApplicationService;
import ru.bowling.bowlingapp.Service.AdminCabinetService;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final AdminCabinetService adminCabinetService;
    private final FreeMechanicApplicationService freeMechanicApplicationService;

    @GetMapping("/mechanics")
    public ResponseEntity<AdminMechanicListResponseDTO> getMechanicsOverview() {
        return ResponseEntity.ok(adminService.getMechanicsOverview());
    }

    @GetMapping("/registrations")
    public ResponseEntity<List<AdminRegistrationApplicationDTO>> listRegistrations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        return ResponseEntity.ok(adminCabinetService.listRegistrationApplications(page, size));
    }

    @PostMapping("/registrations/{userId}/approve")
    public ResponseEntity<AdminRegistrationApplicationDTO> approveRegistration(@PathVariable Long userId) {
        return ResponseEntity.ok(adminCabinetService.approveRegistration(userId));
    }

    @PostMapping("/registrations/{userId}/reject")
    public ResponseEntity<AdminRegistrationApplicationDTO> rejectRegistration(@PathVariable Long userId,
                                                                              @RequestBody(required = false) String reason) {
        return ResponseEntity.ok(adminCabinetService.rejectRegistration(userId, reason));
    }

    @GetMapping("/free-mechanics/applications")
    public ResponseEntity<List<FreeMechanicApplicationResponseDTO>> listFreeMechanicApplications() {
        return ResponseEntity.ok(freeMechanicApplicationService.listApplications());
    }

    @PostMapping("/free-mechanics/applications/{applicationId}/approve")
    public ResponseEntity<FreeMechanicApplicationResponseDTO> approveFreeMechanic(
            @PathVariable Long applicationId,
            @RequestBody MechanicApplicationDecisionDTO decision
    ) {
        return ResponseEntity.ok(freeMechanicApplicationService.approve(applicationId, decision));
    }

    @PostMapping("/free-mechanics/applications/{applicationId}/reject")
    public ResponseEntity<FreeMechanicApplicationResponseDTO> rejectFreeMechanic(
            @PathVariable Long applicationId,
            @RequestBody MechanicApplicationDecisionDTO decision
    ) {
        return ResponseEntity.ok(freeMechanicApplicationService.reject(applicationId, decision != null ? decision.getComment() : null));
    }

    @PatchMapping("/free-mechanics/{userId}/account")
    public ResponseEntity<AdminRegistrationApplicationDTO> updateFreeMechanicAccount(
            @PathVariable Long userId,
            @RequestBody AdminAccountUpdateDTO update
    ) {
        return ResponseEntity.ok(adminCabinetService.updateFreeMechanicAccount(userId, update));
    }

    @PatchMapping("/mechanics/{userId}/account")
    public ResponseEntity<AdminRegistrationApplicationDTO> convertMechanicAccount(
            @PathVariable Long userId,
            @RequestBody AdminMechanicAccountChangeDTO change
    ) {
        return ResponseEntity.ok(adminCabinetService.convertMechanicAccount(userId, change));
    }

    @PatchMapping("/mechanics/{profileId}/clubs")
    public ResponseEntity<AdminRegistrationApplicationDTO> changeMechanicClub(
            @PathVariable Long profileId,
            @RequestBody MechanicClubLinkRequestDTO request
    ) {
        return ResponseEntity.ok(adminCabinetService.changeMechanicClubLink(profileId, request));
    }

    @GetMapping("/attestations")
    public ResponseEntity<List<AttestationApplicationDTO>> listAttestations() {
        return ResponseEntity.ok(adminCabinetService.listAttestationApplications());
    }

    @PutMapping("/attestations/{id}/decision")
    public ResponseEntity<AttestationApplicationDTO> decideAttestation(
            @PathVariable Long id,
            @RequestBody AttestationDecisionDTO decision
    ) {
        return ResponseEntity.ok(adminCabinetService.decideAttestation(id, decision));
    }

    @GetMapping("/supplier-complaints")
    public ResponseEntity<List<AdminComplaintDTO>> listComplaints() {
        return ResponseEntity.ok(adminCabinetService.listSupplierComplaints());
    }

    @PatchMapping("/supplier-complaints/{reviewId}")
    public ResponseEntity<AdminComplaintDTO> updateComplaint(
            @PathVariable Long reviewId,
            @RequestParam(required = false) SupplierComplaintStatus status,
            @RequestParam(required = false) Boolean resolved,
            @RequestParam(required = false) String notes
    ) {
        return ResponseEntity.ok(adminCabinetService.updateComplaintStatus(reviewId, status, resolved, notes));
    }

    @GetMapping("/help-requests")
    public ResponseEntity<List<AdminHelpRequestDTO>> listHelpRequests() {
        return ResponseEntity.ok(adminCabinetService.listHelpRequests());
    }

    @GetMapping("/staff/status-requests")
    public ResponseEntity<List<AdminMechanicStatusChangeDTO>> listMechanicStatusChanges() {
        return ResponseEntity.ok(adminCabinetService.listMechanicStatusChanges());
    }

    @PatchMapping("/staff/{staffId}/status")
    public ResponseEntity<AdminMechanicStatusChangeDTO> updateMechanicStatus(
            @PathVariable Long staffId,
            @RequestBody AdminStaffStatusUpdateDTO update
    ) {
        return ResponseEntity.ok(adminCabinetService.updateMechanicStaffStatus(staffId, update));
    }

    @GetMapping("/appeals")
    public ResponseEntity<List<AdminAppealDTO>> listAppeals() {
        return ResponseEntity.ok(adminCabinetService.listAdministrativeAppeals());
    }

    @PostMapping("/appeals/{appealId}/reply")
    public ResponseEntity<NotificationEvent> replyAppeal(
            @PathVariable String appealId,
            @RequestBody AdminAppealReplyDTO request
    ) {
        return ResponseEntity.ok(adminCabinetService.replyToAppeal(appealId, request));
    }

    @PutMapping("/users/{userId}/verify")
    public ResponseEntity<?> verifyUser(@PathVariable Long userId) {
        adminService.verifyUser(userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/users/{userId}/activate")
    public ResponseEntity<?> activateUser(@PathVariable Long userId) {
        adminService.setUserActiveStatus(userId, true);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/users/{userId}/deactivate")
    public ResponseEntity<?> deactivateUser(@PathVariable Long userId) {
        adminService.setUserActiveStatus(userId, false);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/users/{userId}/reject")
    public ResponseEntity<?> rejectRegistration(@PathVariable Long userId) {
        adminService.rejectRegistration(userId);
        return ResponseEntity.ok().build();
    }
}
