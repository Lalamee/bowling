package ru.bowling.bowlingapp.Controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.ClubCreateDTO;
import ru.bowling.bowlingapp.DTO.ClubSummaryDTO;
import ru.bowling.bowlingapp.Service.BowlingClubService;

@RestController
@RequestMapping("/api/admin/clubs")
@RequiredArgsConstructor
public class AdminClubController {

    private final BowlingClubService bowlingClubService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ClubSummaryDTO> createClub(@Valid @RequestBody ClubCreateDTO request) {
        return ResponseEntity.ok(bowlingClubService.createClub(request));
    }
}
