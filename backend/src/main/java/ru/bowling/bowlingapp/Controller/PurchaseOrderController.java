package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.PurchaseOrderAcceptanceRequestDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderDetailDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderSummaryDTO;
import ru.bowling.bowlingapp.DTO.SupplierComplaintRequestDTO;
import ru.bowling.bowlingapp.DTO.SupplierReviewRequestDTO;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.PurchaseOrderService;

import java.util.List;

@RestController
@RequestMapping("/api/purchase-orders")
@RequiredArgsConstructor
public class PurchaseOrderController {

    private final PurchaseOrderService purchaseOrderService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','OWNER','CLUB_OWNER','MANAGER','HEAD_MECHANIC','STAFF')")
    public ResponseEntity<List<PurchaseOrderSummaryDTO>> getOrders(
            @RequestParam(value = "clubId", required = false) Long clubId,
            @RequestParam(value = "archived", defaultValue = "false") boolean archived,
            @RequestParam(value = "status", required = false) PurchaseOrderStatus status,
            @RequestParam(value = "hasComplaint", required = false) Boolean hasComplaint,
            @RequestParam(value = "hasReview", required = false) Boolean hasReview) {
        return ResponseEntity.ok(purchaseOrderService.getOrders(clubId, archived, status, hasComplaint, hasReview));
    }

    @GetMapping("/{orderId}")
    @PreAuthorize("hasAnyRole('ADMIN','OWNER','CLUB_OWNER','MANAGER','HEAD_MECHANIC','STAFF')")
    public ResponseEntity<PurchaseOrderDetailDTO> getOrder(@PathVariable Long orderId) {
        return ResponseEntity.ok(purchaseOrderService.getOrderDetails(orderId));
    }

    @PostMapping("/{orderId}/acceptance")
    @PreAuthorize("hasAnyRole('ADMIN','OWNER','CLUB_OWNER','MANAGER','HEAD_MECHANIC','STAFF')")
    public ResponseEntity<PurchaseOrderDetailDTO> acceptOrder(@PathVariable Long orderId,
                                                             @Valid @RequestBody PurchaseOrderAcceptanceRequestDTO request) {
        return ResponseEntity.ok(purchaseOrderService.acceptOrder(orderId, request));
    }

    @PostMapping("/{orderId}/reviews")
    @PreAuthorize("hasAnyRole('ADMIN','OWNER','CLUB_OWNER','MANAGER','HEAD_MECHANIC','STAFF')")
    public ResponseEntity<PurchaseOrderDetailDTO> createReview(@PathVariable Long orderId,
                                                               @Valid @RequestBody SupplierReviewRequestDTO request,
                                                               @AuthenticationPrincipal UserPrincipal principal) {
        Long userId = principal != null ? principal.getId() : null;
        return ResponseEntity.ok(purchaseOrderService.leaveReview(orderId, request, userId));
    }

    @PostMapping("/{orderId}/complaints")
    @PreAuthorize("hasAnyRole('ADMIN','OWNER','CLUB_OWNER','MANAGER','HEAD_MECHANIC','STAFF')")
    public ResponseEntity<PurchaseOrderDetailDTO> submitComplaint(@PathVariable Long orderId,
                                                                  @Valid @RequestBody SupplierComplaintRequestDTO request,
                                                                  @AuthenticationPrincipal UserPrincipal principal) {
        Long userId = principal != null ? principal.getId() : null;
        return ResponseEntity.ok(purchaseOrderService.submitComplaint(orderId, request, userId));
    }
}
