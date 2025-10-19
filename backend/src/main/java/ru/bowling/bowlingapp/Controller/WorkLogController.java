package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.WorkLogDTO;
import ru.bowling.bowlingapp.DTO.WorkLogSearchDTO;
import ru.bowling.bowlingapp.Entity.WorkLog;
import ru.bowling.bowlingapp.Service.WorkLogService;
import ru.bowling.bowlingapp.Security.UserPrincipal;

import java.util.Optional;

@RestController
@RequestMapping("/api/worklogs")
@RequiredArgsConstructor
public class WorkLogController {

    private final WorkLogService workLogService;

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MECHANIC')")
    public ResponseEntity<WorkLogDTO> createWorkLog(@RequestBody WorkLogDTO workLogDTO, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        WorkLog createdWorkLog = workLogService.createWorkLog(workLogDTO, userPrincipal.getId());
        return ResponseEntity.ok(convertToDto(createdWorkLog));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MECHANIC')")
    public ResponseEntity<WorkLogDTO> getWorkLog(@PathVariable Long id) {
        WorkLog workLog = workLogService.getWorkLog(id);
        return ResponseEntity.ok(convertToDto(workLog));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MECHANIC')")
    public ResponseEntity<WorkLogDTO> updateWorkLog(@PathVariable Long id, @RequestBody WorkLogDTO workLogDTO) {
        WorkLog updatedWorkLog = workLogService.updateWorkLog(id, workLogDTO);
        return ResponseEntity.ok(convertToDto(updatedWorkLog));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")
    public ResponseEntity<Void> deleteWorkLog(@PathVariable Long id) {
        workLogService.deleteWorkLog(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'OWNER', 'MECHANIC')")
    public ResponseEntity<Page<WorkLogDTO>> searchWorkLogs(@RequestBody WorkLogSearchDTO searchDTO, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Page<WorkLog> workLogs = workLogService.searchWorkLogs(searchDTO, userPrincipal.getId());
        return ResponseEntity.ok(workLogs.map(this::convertToDto));
    }

    private WorkLogDTO convertToDto(WorkLog workLog) {
        if (workLog == null) {
            return null;
        }
        WorkLogDTO.WorkLogDTOBuilder builder = WorkLogDTO.builder()
                .logId(workLog.getLogId())
                .createdDate(workLog.getCreatedDate())
                .startedDate(workLog.getStartedDate())
                .completedDate(workLog.getCompletedDate())
                .problemDescription(workLog.getProblemDescription())
                .workPerformed(workLog.getWorkPerformed())
                .solutionDescription(workLog.getSolutionDescription())
                .estimatedHours(workLog.getEstimatedHours())
                .actualHours(workLog.getActualHours())
                .laborCost(workLog.getLaborCost())
                .totalPartsCost(workLog.getTotalPartsCost())
                .totalCost(workLog.getTotalCost())
                .priority(workLog.getPriority())
                .approvalDate(workLog.getApprovalDate())
                .managerNotes(workLog.getManagerNotes())
                .qualityRating(workLog.getQualityRating())
                .customerSatisfaction(workLog.getCustomerSatisfaction())
                .warrantyPeriodMonths(workLog.getWarrantyPeriodMonths())
                .nextServiceDate(workLog.getNextServiceDate())
                .isManualEdit(workLog.getIsManualEdit())
                .manualEditReason(workLog.getManualEditReason());

        Optional.ofNullable(workLog.getStatus()).ifPresent(s -> builder.status(s.name()));
        Optional.ofNullable(workLog.getWorkType()).ifPresent(wt -> builder.workType(wt.name()));
        Optional.ofNullable(workLog.getMaintenanceRequest()).ifPresent(mr -> builder.maintenanceRequestId(mr.getRequestId()));
        Optional.ofNullable(workLog.getClub()).ifPresent(c -> builder.clubId(c.getClubId()).clubName(c.getName()));
        Optional.ofNullable(workLog.getEquipment()).ifPresent(e -> builder.equipmentId(e.getEquipmentId()));
        Optional.ofNullable(workLog.getMechanic()).ifPresent(m -> builder.mechanicId(m.getProfileId()).mechanicName(m.getFullName()));
        Optional.ofNullable(workLog.getApprovedBy()).ifPresent(u -> builder.approvedBy(u.getUserId()));
        Optional.ofNullable(workLog.getCreatedBy()).ifPresent(builder::createdBy);
        Optional.ofNullable(workLog.getModifiedBy()).ifPresent(builder::modifiedBy);

        return builder.build();
    }
}
