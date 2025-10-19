package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.Service.AdminService;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;

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
