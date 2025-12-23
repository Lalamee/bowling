package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.ClubAppealRequestDTO;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.DTO.ServiceJournalEntryDTO;
import ru.bowling.bowlingapp.DTO.TechnicalInfoDTO;
import ru.bowling.bowlingapp.DTO.WarningDTO;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.OwnerDashboardService;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/owner-dashboard")
@RequiredArgsConstructor
public class OwnerDashboardController {

    private final OwnerDashboardService ownerDashboardService;

    @GetMapping("/technical-info")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER','ADMIN')")
    public ResponseEntity<List<TechnicalInfoDTO>> getTechnicalInfo(@AuthenticationPrincipal UserPrincipal principal,
                                                                   @RequestParam(name = "clubId", required = false) Long clubId) {
        return ResponseEntity.ok(ownerDashboardService.getTechnicalInformation(principal.getId(), clubId));
    }

    @GetMapping("/service-history")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER','ADMIN')")
    public ResponseEntity<List<ServiceJournalEntryDTO>> getServiceHistory(@AuthenticationPrincipal UserPrincipal principal,
                                                                         @RequestParam(name = "clubId", required = false) Long clubId,
                                                                         @RequestParam(name = "laneNumber", required = false) Integer laneNumber,
                                                                         @RequestParam(name = "start", required = false) LocalDateTime start,
                                                                         @RequestParam(name = "end", required = false) LocalDateTime end,
                                                                         @RequestParam(name = "workType", required = false) WorkType workType,
                                                                         @RequestParam(name = "status", required = false) WorkLogStatus status) {
        return ResponseEntity.ok(ownerDashboardService.getServiceJournal(principal.getId(), clubId, laneNumber, start, end, workType, status));
    }

    @GetMapping("/warnings")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER','ADMIN')")
    public ResponseEntity<List<WarningDTO>> getWarnings(@AuthenticationPrincipal UserPrincipal principal,
                                                        @RequestParam(name = "clubId", required = false) Long clubId) {
        return ResponseEntity.ok(ownerDashboardService.getWarnings(principal.getId(), clubId));
    }

    @GetMapping("/notifications")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER','ADMIN','MECHANIC')")
    public ResponseEntity<List<NotificationEvent>> getNotifications(@AuthenticationPrincipal UserPrincipal principal,
                                                                   @RequestParam(name = "clubId", required = false) Long clubId,
                                                                   @RequestParam(name = "role", required = false) String role) {
        return ResponseEntity.ok(ownerDashboardService.getManagerNotifications(principal.getId(), clubId, parseRole(role)));
    }

    @PostMapping("/appeals")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER')")
    public ResponseEntity<NotificationEvent> submitAppeal(@AuthenticationPrincipal UserPrincipal principal,
                                                          @RequestBody ClubAppealRequestDTO request) {
        return ResponseEntity.ok(ownerDashboardService.submitClubAppeal(principal.getId(), request));
    }

    private RoleName parseRole(String rawRole) {
        if (rawRole == null || rawRole.isBlank()) {
            return null;
        }
        try {
            return RoleName.from(rawRole);
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }
}
