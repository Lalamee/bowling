package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class EquipmentComponentDTO {
    Long componentId;
    String name;
    String manufacturer;
    String category;
    String code;
    String notes;
    Long parentId;
}
