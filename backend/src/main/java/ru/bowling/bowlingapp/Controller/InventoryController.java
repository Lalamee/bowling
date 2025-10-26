package ru.bowling.bowlingapp.Controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.Service.InventoryService;

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

    @Autowired
    private InventoryService inventoryService;

    @GetMapping("/search")
    public ResponseEntity<List<PartDto>> searchParts(@RequestParam String query, @RequestParam(required = false) Long clubId) {
        List<PartDto> parts = inventoryService.searchParts(query, clubId);
        return ResponseEntity.ok(parts);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartDto> getPartById(@PathVariable Long id) {
        PartDto part = inventoryService.getPartById(id);
        return ResponseEntity.ok(part);
    }

    @PostMapping("/reserve")
    public ResponseEntity<Void> reservePart(@RequestBody ReservationRequestDto reservationRequestDto) {
        inventoryService.reservePart(reservationRequestDto);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/release")
    public ResponseEntity<Void> releasePart(@RequestBody ReservationRequestDto reservationRequestDto) {
        inventoryService.releasePart(reservationRequestDto);
        return ResponseEntity.ok().build();
    }
}
