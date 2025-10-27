package ru.bowling.bowlingapp.Controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.CreateStaffRequestDTO;
import ru.bowling.bowlingapp.DTO.CreateStaffResponseDTO;
import ru.bowling.bowlingapp.DTO.StandardResponseDTO;
import ru.bowling.bowlingapp.Service.ClubStaffService;

import java.util.Map;

@RestController
@RequestMapping("/api/clubs")
@RequiredArgsConstructor
public class ClubStaffController {

    private final ClubStaffService clubStaffService;

    @GetMapping("/{clubId}/staff")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER', 'MANAGER')")
    public ResponseEntity<?> getClubStaff(@PathVariable Long clubId) {
        return ResponseEntity.ok(clubStaffService.getClubStaff(clubId));
    }

    @PostMapping("/{clubId}/staff")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<CreateStaffResponseDTO> createStaff(
            @PathVariable Long clubId,
            @Valid @RequestBody CreateStaffRequestDTO requestDTO,
            Authentication authentication
    ) {
        String requestedBy = authentication != null ? authentication.getName() : null;
        CreateStaffResponseDTO response = clubStaffService.createStaff(clubId, requestDTO, requestedBy);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Назначить сотрудника в клуб
     * POST /api/clubs/{clubId}/staff/{userId}
     */
    @PostMapping("/{clubId}/staff/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<?> assignStaff(
        @PathVariable Long clubId,
        @PathVariable Long userId,
        @RequestBody(required = false) Map<String, Object> body
    ) {
        // TODO: Реализовать назначение сотрудника
        return ResponseEntity.ok(
            StandardResponseDTO.builder()
                .message("Staff member assigned successfully")
                .status("success")
                .build()
        );
    }

    /**
     * Удалить сотрудника из клуба
     * DELETE /api/clubs/{clubId}/staff/{userId}
     */
    @DeleteMapping("/{clubId}/staff/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<StandardResponseDTO> removeStaff(
        @PathVariable Long clubId,
        @PathVariable Long userId,
        Authentication authentication
    ) {
        String requestedBy = authentication != null ? authentication.getName() : null;
        clubStaffService.removeStaff(clubId, userId, requestedBy);
        return ResponseEntity.ok(
            StandardResponseDTO.builder()
                .message("Staff member removed successfully")
                .status("success")
                .build()
        );
    }

    /**
     * Обновить роль сотрудника в клубе
     * PUT /api/clubs/{clubId}/staff/{userId}/role
     */
    @PutMapping("/{clubId}/staff/{userId}/role")
    @PreAuthorize("hasAnyRole('ADMIN', 'CLUB_OWNER')")
    public ResponseEntity<?> updateStaffRole(
        @PathVariable Long clubId,
        @PathVariable Long userId,
        @RequestBody Map<String, String> body
    ) {
        // TODO: Реализовать обновление роли
        return ResponseEntity.ok(
            StandardResponseDTO.builder()
                .message("Staff role updated successfully")
                .status("success")
                .build()
        );
    }
}
