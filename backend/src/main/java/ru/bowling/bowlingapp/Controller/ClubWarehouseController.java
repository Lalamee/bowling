package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.WarehouseItemRequestDTO;
import ru.bowling.bowlingapp.DTO.WarehouseItemResponseDTO;
import ru.bowling.bowlingapp.Service.ClubWarehouseService;

import java.util.List;

@RestController
@RequestMapping("/api/clubs/{clubId}/warehouse")
@RequiredArgsConstructor
public class ClubWarehouseController {

    private final ClubWarehouseService clubWarehouseService;

    @GetMapping("/items")
    public ResponseEntity<List<WarehouseItemResponseDTO>> getWarehouseItems(@PathVariable Long clubId) {
        List<WarehouseItemResponseDTO> items = clubWarehouseService.getWarehouseItems(clubId);
        return ResponseEntity.ok(items);
    }

    @PostMapping("/items")
    public ResponseEntity<WarehouseItemResponseDTO> createWarehouseItem(
            @PathVariable Long clubId,
            @RequestBody WarehouseItemRequestDTO request
    ) {
        WarehouseItemResponseDTO response = clubWarehouseService.upsertInventoryItem(clubId, request);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/items/{inventoryId}")
    public ResponseEntity<WarehouseItemResponseDTO> updateWarehouseItem(
            @PathVariable Long clubId,
            @PathVariable Long inventoryId,
            @RequestBody(required = false) WarehouseItemRequestDTO request
    ) {
        if (request == null) {
            request = new WarehouseItemRequestDTO();
        }
        request.setInventoryId(inventoryId);
        WarehouseItemResponseDTO response = clubWarehouseService.upsertInventoryItem(clubId, request);
        return ResponseEntity.ok(response);
    }
}
