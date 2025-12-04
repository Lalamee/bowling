package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.EquipmentComponentDTO;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EquipmentComponentService {

    private final EquipmentComponentRepository equipmentComponentRepository;

    public List<EquipmentComponentDTO> getComponents(Long parentId) {
        List<EquipmentComponent> components = parentId == null
                ? equipmentComponentRepository.findByParentIsNullOrderByComponentIdAsc()
                : equipmentComponentRepository.findByParent_ComponentIdOrderByComponentIdAsc(parentId);

        return components.stream()
                .map(this::toDto)
                .toList();
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
