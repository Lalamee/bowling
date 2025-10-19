package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClubEquipmentTypeDTO {
    
    @NotNull
    private Integer equipmentTypeId; // ID типа оборудования (AMF, Brunswick, VIA, XIMA, Other)
    
    @Min(0)
    private Integer lanesCount; // количество дорожек с данным типом оборудования
    
    private String otherName; // если выбран "Other" - указать название
}
