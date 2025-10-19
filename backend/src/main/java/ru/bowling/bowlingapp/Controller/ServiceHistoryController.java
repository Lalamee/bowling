package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.ServiceHistoryDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.ServiceHistoryService;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/service-history")
@RequiredArgsConstructor
public class ServiceHistoryController {

    private final ServiceHistoryService serviceHistoryService;

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
    public ResponseEntity<ServiceHistoryDTO> createServiceHistory(@RequestBody ServiceHistoryDTO dto, @AuthenticationPrincipal UserPrincipal userPrincipal) {
        ServiceHistory serviceHistory = serviceHistoryService.createServiceRecord(convertToEntity(dto), userPrincipal.getId());
        return ResponseEntity.ok(convertToDto(serviceHistory));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MECHANIC')")
    public ResponseEntity<ServiceHistoryDTO> getServiceHistory(@PathVariable Long id) {
        ServiceHistory serviceHistory = serviceHistoryService.getServiceHistoryById(id)
                .orElseThrow(() -> new RuntimeException("ServiceHistory not found"));
        return ResponseEntity.ok(convertToDto(serviceHistory));
    }

    @GetMapping("/club/{clubId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
    public ResponseEntity<List<ServiceHistoryDTO>> getServiceHistoryByClub(@PathVariable Long clubId) {
        List<ServiceHistory> histories = serviceHistoryService.getServiceHistoryByClub(clubId);
        return ResponseEntity.ok(histories.stream().map(this::convertToDto).collect(Collectors.toList()));
    }

    private ServiceHistoryDTO convertToDto(ServiceHistory entity) {
        if (entity == null) return null;

        ServiceHistoryDTO.ServiceHistoryDTOBuilder builder = ServiceHistoryDTO.builder()
                .serviceId(entity.getServiceId())
                .laneNumber(entity.getLaneNumber())
                .serviceDate(entity.getServiceDate())
                .description(entity.getDescription())
                .partsReplaced(entity.getPartsReplaced())
                .laborHours(entity.getLaborHours())
                .totalCost(entity.getTotalCost())
                .nextServiceDue(entity.getNextServiceDue())
                .warrantyUntil(entity.getWarrantyUntil())
                .serviceNotes(entity.getServiceNotes())
                .performanceMetrics(entity.getPerformanceMetrics())
                .createdDate(entity.getCreatedDate())
                .createdBy(entity.getCreatedBy());

        if (entity.getClub() != null) {
            builder.clubId(entity.getClub().getClubId()).clubName(entity.getClub().getName());
        }
        if (entity.getEquipment() != null) {
            builder.equipmentId(entity.getEquipment().getEquipmentId());
        }
        if (entity.getServiceType() != null) {
            builder.serviceType(entity.getServiceType().name());
        }
        if (entity.getPerformedBy() != null) {
            builder.performedByMechanicId(entity.getPerformedBy().getProfileId())
                   .performedByMechanicName(entity.getPerformedBy().getFullName());
        }
        if (entity.getSupervisedBy() != null) {
            builder.supervisedByUserId(entity.getSupervisedBy().getUserId());
        }

        return builder.build();
    }

    private ServiceHistory convertToEntity(ServiceHistoryDTO dto) {
        if (dto == null) return null;

        ServiceHistory.ServiceHistoryBuilder builder = ServiceHistory.builder()
                .serviceId(dto.getServiceId())
                .laneNumber(dto.getLaneNumber())
                .serviceDate(dto.getServiceDate())
                .description(dto.getDescription())
                .partsReplaced(dto.getPartsReplaced())
                .laborHours(dto.getLaborHours())
                .totalCost(dto.getTotalCost())
                .nextServiceDue(dto.getNextServiceDue())
                .warrantyUntil(dto.getWarrantyUntil())
                .serviceNotes(dto.getServiceNotes())
                .performanceMetrics(dto.getPerformanceMetrics())
                .createdDate(dto.getCreatedDate())
                .createdBy(dto.getCreatedBy());

        // Note: Setting related entities by ID requires fetching them from repositories.
        // This should be handled in the service layer, not the controller.
        // This conversion is simplified for demonstration.

        return builder.build();
    }
}
