package ru.bowling.bowlingapp.Controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.AddRequestPartsDTO;
import ru.bowling.bowlingapp.DTO.ApproveRejectRequestDTO;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.StandardResponseDTO;
import ru.bowling.bowlingapp.Service.MaintenanceRequestService;

import java.util.List;

@RestController
@RequestMapping("/api/maintenance")
@RequiredArgsConstructor
public class MaintenanceController {

	private final MaintenanceRequestService maintenanceRequestService;

	@PostMapping("/requests")
	public ResponseEntity<?> createPartRequest(@Valid @RequestBody PartRequestDTO requestDTO, Authentication authentication) {
		if (authentication == null || !authentication.isAuthenticated()) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
					.body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
		}
		MaintenanceRequestResponseDTO response = maintenanceRequestService.createPartRequest(requestDTO);
		return ResponseEntity.status(HttpStatus.CREATED).body(response);
	}

        @GetMapping("/requests")
        public ResponseEntity<List<MaintenanceRequestResponseDTO>> getAllRequests(Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
                List<MaintenanceRequestResponseDTO> requests = maintenanceRequestService.getAllRequests();
                return ResponseEntity.ok(requests);
        }

        @GetMapping("/requests/{requestId}")
        public ResponseEntity<MaintenanceRequestResponseDTO> getRequestById(@PathVariable Long requestId,
                        Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
                MaintenanceRequestResponseDTO request = maintenanceRequestService.getRequestById(requestId);
                return ResponseEntity.ok(request);
        }

        @GetMapping("/requests/status/{status}")
        public ResponseEntity<List<MaintenanceRequestResponseDTO>> getRequestsByStatus(@PathVariable String status, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
		List<MaintenanceRequestResponseDTO> requests = maintenanceRequestService.getRequestsByStatus(status);
		return ResponseEntity.ok(requests);
	}

        @GetMapping("/requests/mechanic/{mechanicId}")
        public ResponseEntity<List<MaintenanceRequestResponseDTO>> getRequestsByMechanic(@PathVariable Long mechanicId, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
                List<MaintenanceRequestResponseDTO> requests = maintenanceRequestService.getRequestsByMechanic(mechanicId);
                return ResponseEntity.ok(requests);
        }

        @GetMapping("/requests/club/{clubId}")
        public ResponseEntity<List<MaintenanceRequestResponseDTO>> getRequestsByClub(@PathVariable Long clubId, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
                List<MaintenanceRequestResponseDTO> requests = maintenanceRequestService.getRequestsByClub(clubId, authentication.getName());
                return ResponseEntity.ok(requests);
        }

        @PutMapping("/requests/{requestId}/approve")
        public ResponseEntity<?> approveRequest(@PathVariable Long requestId, @Valid @RequestBody ApproveRejectRequestDTO request, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                        .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
		}
                MaintenanceRequestResponseDTO response = maintenanceRequestService.approveRequest(
                                requestId,
                                request.getManagerNotes(),
                                request.getPartsAvailability());
		return ResponseEntity.ok(response);
	}

	@PutMapping("/requests/{requestId}/reject")
	public ResponseEntity<?> rejectRequest(@PathVariable Long requestId, @Valid @RequestBody ApproveRejectRequestDTO request, Authentication authentication) {
		if (authentication == null || !authentication.isAuthenticated()) {
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
					.body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
		}
		MaintenanceRequestResponseDTO response = maintenanceRequestService.rejectRequest(requestId, request.getRejectionReason());
		return ResponseEntity.ok(response);
	}

	@PutMapping("/requests/{id}/publish")
	public ResponseEntity<?> publish(@PathVariable("id") Long id) {
		return ResponseEntity.ok(maintenanceRequestService.publishRequest(id));
	}

	@PutMapping("/requests/{id}/assign/{agentId}")
	public ResponseEntity<?> assign(@PathVariable("id") Long id, @PathVariable("agentId") Long agentId) {
		return ResponseEntity.ok(maintenanceRequestService.assignAgent(id, agentId));
	}

	@PostMapping("/requests/{id}/order")
	public ResponseEntity<?> order(@PathVariable("id") Long id, @RequestBody java.util.Map<String, Object> payload) {
		return ResponseEntity.ok(maintenanceRequestService.orderParts(id, payload));
	}

	@PutMapping("/requests/{id}/deliver")
	public ResponseEntity<?> deliver(@PathVariable("id") Long id, @RequestBody java.util.Map<String, Object> payload) {
		return ResponseEntity.ok(maintenanceRequestService.markDelivered(id, payload));
	}

	@PutMapping("/requests/{id}/issue")
	public ResponseEntity<?> issue(@PathVariable("id") Long id, @RequestBody java.util.Map<String, Object> payload) {
		return ResponseEntity.ok(maintenanceRequestService.markIssued(id, payload));
	}

        @PutMapping("/requests/{id}/close")
        public ResponseEntity<?> close(@PathVariable("id") Long id, @RequestBody(required = false) java.util.Map<String, Object> payload) {
                return ResponseEntity.ok(maintenanceRequestService.closeRequest(id, payload));
        }

        @PutMapping("/requests/{id}/complete")
        public ResponseEntity<?> complete(@PathVariable("id") Long id, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                        .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
                }
                MaintenanceRequestResponseDTO response = maintenanceRequestService.completeRequest(id);
                return ResponseEntity.ok(response);
        }

        @PutMapping("/requests/{id}/unrepairable")
        public ResponseEntity<?> unrepairable(@PathVariable("id") Long id, @RequestBody ApproveRejectRequestDTO request) {
                return ResponseEntity.ok(maintenanceRequestService.markAsUnrepairable(id, request.getRejectionReason()));
        }

        @PostMapping("/requests/{id}/parts")
        public ResponseEntity<?> addPartsToRequest(@PathVariable("id") Long id, @Valid @RequestBody AddRequestPartsDTO request, Authentication authentication) {
                if (authentication == null || !authentication.isAuthenticated()) {
                        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                        .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
                }
                if (request == null || request.getRequestedParts() == null || request.getRequestedParts().isEmpty()) {
                        return ResponseEntity.badRequest()
                                        .body(StandardResponseDTO.builder().status("error").message("At least one part is required").build());
                }
                MaintenanceRequestResponseDTO response = maintenanceRequestService.addPartsToRequest(id, request.getRequestedParts());
                return ResponseEntity.ok(response);
        }
}