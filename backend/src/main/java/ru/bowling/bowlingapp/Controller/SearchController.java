package ru.bowling.bowlingapp.Controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.GlobalSearchResponseDTO;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.GlobalSearchService;

@RestController
@RequestMapping("/api/search")
public class SearchController {

    private final GlobalSearchService globalSearchService;

    public SearchController(GlobalSearchService globalSearchService) {
        this.globalSearchService = globalSearchService;
    }

    @GetMapping("/global")
    public ResponseEntity<GlobalSearchResponseDTO> search(
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "limit", required = false) Integer limit,
            Authentication authentication
    ) {
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal userPrincipal)) {
            return ResponseEntity.status(401).build();
        }

        int resolvedLimit = resolveLimit(limit);
        GlobalSearchResponseDTO response = globalSearchService.search(query, resolvedLimit, userPrincipal.getId());
        return ResponseEntity.ok(response);
    }

    private int resolveLimit(Integer limit) {
        if (limit == null) {
            return 5;
        }
        int normalized = Math.max(1, Math.min(limit, 20));
        return normalized;
    }
}
