package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.MechanicDirectoryDetailDTO;
import ru.bowling.bowlingapp.DTO.MechanicDirectorySummaryDTO;
import ru.bowling.bowlingapp.DTO.SpecialistCardDTO;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;
import ru.bowling.bowlingapp.Service.MechanicDirectoryService;

import java.util.List;

@RestController
@RequestMapping("/api/mechanics")
@RequiredArgsConstructor
public class MechanicDirectoryController {

    private final MechanicDirectoryService mechanicDirectoryService;

    @GetMapping
    public ResponseEntity<List<MechanicDirectorySummaryDTO>> search(
            @RequestParam(name = "query", required = false) String query,
            @RequestParam(name = "region", required = false) String region,
            @RequestParam(name = "certification", required = false) String certification
    ) {
        return ResponseEntity.ok(mechanicDirectoryService.searchMechanics(query, region, certification));
    }

    @GetMapping("/specialists")
    public ResponseEntity<List<SpecialistCardDTO>> specialistBase(
            @RequestParam(name = "region", required = false) String region,
            @RequestParam(name = "specializationId", required = false) Integer specializationId,
            @RequestParam(name = "grade", required = false) MechanicGrade grade,
            @RequestParam(name = "minRating", required = false) Double minRating
    ) {
        return ResponseEntity.ok(mechanicDirectoryService.getSpecialistBase(region, specializationId, grade, minRating));
    }

    @GetMapping("/{profileId}")
    public ResponseEntity<MechanicDirectoryDetailDTO> detail(@PathVariable Long profileId) {
        return ResponseEntity.ok(mechanicDirectoryService.getMechanicDetail(profileId));
    }
}

