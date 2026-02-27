package ru.bowling.bowlingapp.Controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.integration.onec.dto.OneCSyncStatusDto;
import ru.bowling.bowlingapp.integration.onec.exception.OneCSyncException;
import ru.bowling.bowlingapp.integration.onec.service.OneCSyncService;

@RestController
@RequestMapping("/api/inventory/1c")
public class OneCSyncController {

    private final OneCSyncService oneCSyncService;

    public OneCSyncController(OneCSyncService oneCSyncService) {
        this.oneCSyncService = oneCSyncService;
    }

    @PostMapping("/sync")
    public ResponseEntity<OneCSyncStatusDto> syncNow() {
        try {
            return ResponseEntity.ok(oneCSyncService.runManualSync());
        } catch (OneCSyncException ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(oneCSyncService.getLastStatus());
        }
    }

    @GetMapping("/sync/status")
    public ResponseEntity<OneCSyncStatusDto> getLastStatus() {
        return ResponseEntity.ok(oneCSyncService.getLastStatus());
    }
}
