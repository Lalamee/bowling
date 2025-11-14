package ru.bowling.bowlingapp.Controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.InventorySearchRequest;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.WarehouseSummaryDto;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.InventoryAvailabilityFilter;
import ru.bowling.bowlingapp.Service.InventoryService;

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

    @Autowired
    private InventoryService inventoryService;

    @GetMapping("/search")
    public ResponseEntity<List<PartDto>> searchParts(@RequestParam(required = false) String query,
                                                     @RequestParam(required = false) Integer warehouseId,
                                                     @RequestParam(required = false) Long clubId,
                                                     @RequestParam(required = false) String availability,
                                                     @RequestParam(required = false, name = "category") String categoryCode) {
        InventorySearchRequest request = InventorySearchRequest.builder()
                .query(query)
                .warehouseId(warehouseId)
                .clubId(clubId)
                .categoryCode(categoryCode)
                .availability(InventoryAvailabilityFilter.fromString(availability))
                .build();
        return ResponseEntity.ok(inventoryService.searchParts(request));
    }

    @GetMapping("/warehouses")
    public ResponseEntity<List<WarehouseSummaryDto>> getAccessibleWarehouses(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        if (userPrincipal == null) {
            return ResponseEntity.status(401).build();
        }
        List<WarehouseSummaryDto> warehouses = inventoryService.getAccessibleWarehouses(userPrincipal.getId());
        return ResponseEntity.ok(warehouses);
        // TODO: добавить /api/inventory/warehouses/{id}/movements для истории операций склада
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
