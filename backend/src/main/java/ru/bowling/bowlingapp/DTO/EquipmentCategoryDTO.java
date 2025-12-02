package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class EquipmentCategoryDTO {
    Long id;
    Long parentId;
    Integer level;
    String brand;
    String nameRu;
    String nameEn;
    Integer sortOrder;
    boolean active;
}
