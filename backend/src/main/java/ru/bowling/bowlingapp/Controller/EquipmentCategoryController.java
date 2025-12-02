package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.EquipmentCategoryDTO;
import ru.bowling.bowlingapp.Service.EquipmentCategoryService;

import java.util.List;

/**
 * Stepwise equipment search endpoint used by the UI.
 * <p>
 * Call order expected by the frontend:
 * <ol>
 *     <li>GET /api/equipment/categories?brand={brand}&level=1 — fetch root brand/category entries (parentId is omitted).</li>
 *     <li>GET /api/equipment/categories?brand={brand}&parentId={rootId} — fetch second-level categories.</li>
 *     <li>GET /api/equipment/categories?brand={brand}&parentId={categoryId} — fetch children of a category (models/lines).</li>
 * </ol>
 * If a caller provides a {@code level} parameter, it must align with the parent level (root = 1, children = parent.level + 1).
 */
@RestController
@RequestMapping("/api/equipment/categories")
@RequiredArgsConstructor
public class EquipmentCategoryController {

    private final EquipmentCategoryService equipmentCategoryService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MECHANIC','HEAD_MECHANIC','CLUB_MANAGER','CLUB_OWNER','ADMIN')")
    public ResponseEntity<List<EquipmentCategoryDTO>> getCategories(
            @RequestParam(value = "brand", required = false) String brand,
            @RequestParam(value = "parentId", required = false) Long parentId,
            @RequestParam(value = "level", required = false) Integer level
    ) {
        List<EquipmentCategoryDTO> categories = equipmentCategoryService.getCategories(brand, parentId, level);
        return ResponseEntity.ok(categories);
    }
}
