package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.EquipmentCategoryDTO;
import ru.bowling.bowlingapp.DTO.EquipmentComponentDTO;
import ru.bowling.bowlingapp.Service.EquipmentCategoryService;

import java.util.List;

@RestController
@RequestMapping("/api/equipment/components")
@RequiredArgsConstructor
public class EquipmentComponentController {

    private final EquipmentCategoryService equipmentCategoryService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MECHANIC','HEAD_MECHANIC','CLUB_MANAGER','CLUB_OWNER','ADMIN')")
    public ResponseEntity<List<EquipmentComponentDTO>> getComponents(
            @RequestParam(value = "brand", required = false) String brand,
            @RequestParam(value = "parentId", required = false) Long parentId,
            @RequestParam(value = "level", required = false) Integer level) {

        List<EquipmentComponentDTO> components = equipmentCategoryService.getCategories(brand, parentId, level).stream()
                .map(this::fromCategory)
                .toList();

        return ResponseEntity.ok(components);
    }

    private EquipmentComponentDTO fromCategory(EquipmentCategoryDTO category) {
        return EquipmentComponentDTO.builder()
                .componentId(category.getId())
                .name(category.getNameRu())
                .manufacturer(category.getBrand())
                .category(category.getNameEn())
                .code(null)
                .notes(null)
                .parentId(category.getParentId())
                .build();
    }
}
