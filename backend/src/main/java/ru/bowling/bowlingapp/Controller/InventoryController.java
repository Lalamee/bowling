package ru.bowling.bowlingapp.Controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import ru.bowling.bowlingapp.DTO.InventorySearchRequest;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.WarehouseSummaryDto;
import ru.bowling.bowlingapp.DTO.WarehouseMovementDto;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.InventoryAvailabilityFilter;
import ru.bowling.bowlingapp.Service.InventoryService;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

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
                                                     @RequestParam(required = false, name = "category") String categoryCode,
                                                     @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<WarehouseSummaryDto> accessible = requireAccessibleWarehouses(userPrincipal);
        Set<Integer> allowedWarehouseIds = extractWarehouseIds(accessible);
        Integer requestedWarehouseId = resolveRequestedWarehouseId(warehouseId, clubId);
        assertWarehouseAccess(allowedWarehouseIds, requestedWarehouseId);

        InventorySearchRequest request = InventorySearchRequest.builder()
                .query(query)
                .warehouseId(requestedWarehouseId)
                .clubId(clubId)
                .categoryCode(categoryCode)
                .availability(InventoryAvailabilityFilter.fromString(availability))
                .allowedWarehouseIds(allowedWarehouseIds)
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
    }

    @GetMapping("/warehouses/{id}/movements")
    public ResponseEntity<List<WarehouseMovementDto>> getWarehouseMovements(@PathVariable("id") Integer warehouseId,
                                                                            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Set<Integer> allowedWarehouseIds = extractWarehouseIds(requireAccessibleWarehouses(userPrincipal));
        assertWarehouseAccess(allowedWarehouseIds, warehouseId);
        List<WarehouseMovementDto> movements = inventoryService.getWarehouseMovements(warehouseId);
        return ResponseEntity.ok(movements);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PartDto> getPartById(@PathVariable Long id,
                                               @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Set<Integer> allowedWarehouseIds = extractWarehouseIds(requireAccessibleWarehouses(userPrincipal));
        PartDto part = inventoryService.getPartById(id);
        assertWarehouseAccess(allowedWarehouseIds, part != null ? part.getWarehouseId() : null);
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

    private List<WarehouseSummaryDto> requireAccessibleWarehouses(UserPrincipal principal) {
        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        List<WarehouseSummaryDto> accessible = inventoryService.getAccessibleWarehouses(principal.getId());
        if (accessible == null || accessible.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Нет доступных складов для пользователя");
        }
        return accessible;
    }

    private Set<Integer> extractWarehouseIds(List<WarehouseSummaryDto> warehouses) {
        if (warehouses == null) {
            return Set.of();
        }
        Set<Integer> ids = warehouses.stream()
                .map(WarehouseSummaryDto::getWarehouseId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (ids.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Склады для пользователя не настроены");
        }
        return ids;
    }

    private Integer resolveRequestedWarehouseId(Integer warehouseId, Long clubId) {
        if (warehouseId != null) {
            return warehouseId;
        }
        if (clubId != null) {
            return Math.toIntExact(clubId);
        }
        return null;
    }

    private void assertWarehouseAccess(Set<Integer> allowedWarehouseIds, Integer requestedWarehouseId) {
        if (requestedWarehouseId == null) {
            return;
        }
        if (allowedWarehouseIds == null || allowedWarehouseIds.isEmpty() || !allowedWarehouseIds.contains(requestedWarehouseId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Склад недоступен для текущего пользователя");
        }
    }
}
