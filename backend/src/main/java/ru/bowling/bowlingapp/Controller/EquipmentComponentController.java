package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.EquipmentComponentDTO;
import ru.bowling.bowlingapp.Service.EquipmentComponentService;

import java.util.List;

@RestController
@RequestMapping("/api/equipment/components")
@RequiredArgsConstructor
public class EquipmentComponentController {

    private final EquipmentComponentService equipmentComponentService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MECHANIC','HEAD_MECHANIC','CLUB_MANAGER','CLUB_OWNER','ADMIN')")
    public ResponseEntity<List<EquipmentComponentDTO>> getComponents(
            @RequestParam(value = "parentId", required = false) Long parentId) {

        List<EquipmentComponentDTO> components = equipmentComponentService.getComponents(parentId);

        return ResponseEntity.ok(components);
    }
}
