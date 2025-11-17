package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.StockIssueDecisionDTO;
import ru.bowling.bowlingapp.Service.MaintenanceRequestService;

import java.util.List;

@RestController
@RequestMapping("/api/requests")
@RequiredArgsConstructor
public class MaintenanceRequestController {

    private final MaintenanceRequestService maintenanceRequestService;

    @PostMapping
    @PreAuthorize("hasAnyRole('MECHANIC', 'CHIEF_MECHANIC', 'HEAD_MECHANIC', 'ADMIN')")
    public ResponseEntity<MaintenanceRequestResponseDTO> createRequest(@RequestBody PartRequestDTO requestDTO) {
        MaintenanceRequestResponseDTO response = maintenanceRequestService.createPartRequest(requestDTO);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'CHIEF_MECHANIC', 'HEAD_MECHANIC', 'STAFF')")
    public ResponseEntity<List<MaintenanceRequestResponseDTO>> getAllRequests() {
        return ResponseEntity.ok(maintenanceRequestService.getAllRequests());
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'CHIEF_MECHANIC', 'HEAD_MECHANIC', 'MECHANIC', 'STAFF')")
    public ResponseEntity<List<MaintenanceRequestResponseDTO>> getRequestsByStatus(@PathVariable String status) {
        return ResponseEntity.ok(maintenanceRequestService.getRequestsByStatus(status));
    }

    @GetMapping("/mechanic/{mechanicId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'CHIEF_MECHANIC', 'HEAD_MECHANIC', 'STAFF')")
    public ResponseEntity<List<MaintenanceRequestResponseDTO>> getRequestsByMechanic(@PathVariable Long mechanicId) {
        return ResponseEntity.ok(maintenanceRequestService.getRequestsByMechanic(mechanicId));
    }

    @PatchMapping("/{requestId}/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'HEAD_MECHANIC', 'STAFF')")
    public ResponseEntity<MaintenanceRequestResponseDTO> approveRequest(@PathVariable Long requestId, @RequestBody(required = false) String managerNotes) {
        return ResponseEntity.ok(maintenanceRequestService.approveRequest(requestId, managerNotes, null));
    }

    @PatchMapping("/{requestId}/stock-issue")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'HEAD_MECHANIC', 'STAFF')")
    public ResponseEntity<MaintenanceRequestResponseDTO> issueFromStock(@PathVariable Long requestId,
                                                                        @RequestBody StockIssueDecisionDTO decisionDTO) {
        return ResponseEntity.ok(maintenanceRequestService.issueFromStock(requestId, decisionDTO));
    }

    @PatchMapping("/{requestId}/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'CLUB_OWNER', 'HEAD_MECHANIC', 'STAFF')")
    public ResponseEntity<MaintenanceRequestResponseDTO> rejectRequest(@PathVariable Long requestId, @RequestBody(required = false) String managerNotes) {
        return ResponseEntity.ok(maintenanceRequestService.rejectRequest(requestId, managerNotes));
    }

    @PatchMapping("/{requestId}/complete")
    @PreAuthorize("hasAnyRole('MECHANIC', 'CHIEF_MECHANIC', 'HEAD_MECHANIC', 'ADMIN')")
    public ResponseEntity<MaintenanceRequestResponseDTO> completeRequest(@PathVariable Long requestId) {
        return ResponseEntity.ok(maintenanceRequestService.completeRequest(requestId));
    }

//    @PatchMapping("/{requestId}/status")
//    @PreAuthorize("hasAnyRole('ADMIN', 'CHIEF_MECHANIC', 'MECHANIC')")
//    public ResponseEntity<MaintenanceRequestResponseDTO> updateStatus(@PathVariable Long requestId, @RequestParam String status) {
//        return ResponseEntity.ok(maintenanceRequestService.updateStatus(requestId, status));
//    }
}
