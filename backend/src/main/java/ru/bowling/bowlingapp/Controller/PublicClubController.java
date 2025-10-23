package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.ClubSummaryDTO;
import ru.bowling.bowlingapp.Service.BowlingClubService;

import java.util.List;

@RestController
@RequestMapping("/api/public/clubs")
@RequiredArgsConstructor
public class PublicClubController {

    private final BowlingClubService bowlingClubService;

    @GetMapping
    public List<ClubSummaryDTO> getClubs() {
        return bowlingClubService.getAllClubs();
    }
}
