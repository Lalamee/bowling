package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.EquipmentComponentDTO;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/equipment/components")
@RequiredArgsConstructor
public class EquipmentComponentController {

    private final EquipmentComponentRepository equipmentComponentRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('MECHANIC','HEAD_MECHANIC','CLUB_MANAGER','CLUB_OWNER','ADMIN')")
    public ResponseEntity<List<EquipmentComponentDTO>> getComponents(@RequestParam(value = "parentId", required = false) Long parentId) {
        List<EquipmentComponentDTO> components = equipmentComponentRepository.findAll().stream()
                .filter(c -> parentId == null || (c.getParent() != null && parentId.equals(c.getParent().getComponentId())))
                .map(this::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(components);
    }

    private EquipmentComponentDTO toDto(EquipmentComponent component) {
        return EquipmentComponentDTO.builder()
                .componentId(component.getComponentId())
                .name(component.getName())
                .manufacturer(component.getManufacturer())
                .category(component.getCategory())
                .code(component.getCode())
                .notes(component.getNotes())
                .parentId(component.getParent() != null ? component.getParent().getComponentId() : null)
                .build();
    }
}
