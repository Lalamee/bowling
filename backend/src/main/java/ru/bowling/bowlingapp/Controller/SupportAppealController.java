package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.DTO.SupportAppealRequestDTO;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.SupportAppealService;

@RestController
@RequestMapping("/api/support")
@RequiredArgsConstructor
public class SupportAppealController {

    private final SupportAppealService supportAppealService;

    @PostMapping("/appeals")
    @PreAuthorize("hasAnyRole('CLUB_OWNER','HEAD_MECHANIC','CLUB_MANAGER','MECHANIC','ADMIN')")
    public ResponseEntity<NotificationEvent> submitAppeal(@AuthenticationPrincipal UserPrincipal principal,
                                                          @RequestBody SupportAppealRequestDTO request) {
        return ResponseEntity.ok(supportAppealService.submitSupportAppeal(principal.getId(), request));
    }
}
