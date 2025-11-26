package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.AdminMechanicListResponseDTO;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationResponseDTO;
import ru.bowling.bowlingapp.DTO.MechanicApplicationDecisionDTO;
import ru.bowling.bowlingapp.Service.AdminService;
import ru.bowling.bowlingapp.Service.FreeMechanicApplicationService;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final FreeMechanicApplicationService freeMechanicApplicationService;

    @GetMapping("/mechanics")
    public ResponseEntity<AdminMechanicListResponseDTO> getMechanicsOverview() {
        return ResponseEntity.ok(adminService.getMechanicsOverview());
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
