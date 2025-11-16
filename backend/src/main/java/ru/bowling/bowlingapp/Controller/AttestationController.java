package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.Service.AttestationService;

import java.util.List;

@RestController
@RequestMapping("/api/attestations")
@RequiredArgsConstructor
public class AttestationController {

    private final AttestationService attestationService;

    @GetMapping("/applications")
    public ResponseEntity<List<AttestationApplicationDTO>> listApplications() {
        return ResponseEntity.ok(attestationService.listApplications());
    }

    @PostMapping("/applications")
    public ResponseEntity<AttestationApplicationDTO> submitApplication(@RequestBody AttestationApplicationDTO dto) {
        return ResponseEntity.ok(attestationService.submitApplication(dto));
    }

    @PutMapping("/applications/{id}/status")
    public ResponseEntity<AttestationApplicationDTO> updateStatus(
            @PathVariable Long id,
            @RequestParam String status,
            @RequestParam(required = false) String comment
    ) {
        return ResponseEntity.ok(attestationService.updateStatus(id, status, comment));
    }
}

