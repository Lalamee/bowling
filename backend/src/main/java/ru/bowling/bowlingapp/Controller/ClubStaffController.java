package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.StandardResponseDTO;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/clubs")
@RequiredArgsConstructor
public class ClubStaffController {

    /**
     * Получить список сотрудников клуба
     * GET /api/clubs/{clubId}/staff
     */
    @GetMapping("/{clubId}/staff")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MANAGER')")
    public ResponseEntity<?> getClubStaff(@PathVariable Long clubId) {
        // TODO: Реализовать получение списка сотрудников
        // Возвращаем пример данных для тестирования
        return ResponseEntity.ok(List.of(
            Map.of(
                "userId", 1,
                "fullName", "Иван Иванов",
                "phone", "+7 (980) 001-01-01",
                "role", "MANAGER",
                "isActive", true
            )
        ));
    }

    /**
     * Назначить сотрудника в клуб
     * POST /api/clubs/{clubId}/staff/{userId}
     */
    @PostMapping("/{clubId}/staff/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
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
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
    public ResponseEntity<?> removeStaff(
        @PathVariable Long clubId,
        @PathVariable Long userId
    ) {
        // TODO: Реализовать удаление сотрудника
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
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
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
