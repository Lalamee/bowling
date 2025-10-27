package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.GlobalSearchResponseDTO;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.GlobalSearchService;
import ru.bowling.bowlingapp.Service.AuthService;

@RestController
@RequestMapping("/api/search")
@RequiredArgsConstructor
public class SearchController {

    private final GlobalSearchService globalSearchService;
    private final AuthService authService;

    @GetMapping("/global")
    public ResponseEntity<GlobalSearchResponseDTO> search(
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "limit", required = false) Integer limit,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).build();
        }

        Long userId = resolveUserId(authentication);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        int resolvedLimit = resolveLimit(limit);
        GlobalSearchResponseDTO response = globalSearchService.search(query, resolvedLimit, userId);
        return ResponseEntity.ok(response);
    }

    private int resolveLimit(Integer limit) {
        if (limit == null) {
            return 5;
        }
        int normalized = Math.max(1, Math.min(limit, 20));
        return normalized;
    }

    private Long resolveUserId(Authentication authentication) {
        Object principal = authentication.getPrincipal();
        if (principal instanceof UserPrincipal userPrincipal && userPrincipal.getId() != null) {
            return userPrincipal.getId();
        }

        String login = authentication.getName();
        if (login == null || login.isBlank()) {
            return null;
        }

        try {
            UserDetails details = authService.loadUserByUsername(login);
            if (details instanceof UserPrincipal resolved && resolved.getId() != null) {
                return resolved.getId();
            }
        } catch (UsernameNotFoundException ex) {
            // fall back to direct phone lookup below
        }

        try {
            return authService.findUserByPhone(login).getUserId();
        } catch (UsernameNotFoundException ex) {
            return null;
        }
    }
}
