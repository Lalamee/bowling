package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BowlingClubDTO {
    @NotBlank
    private String name;

    @NotBlank
    private String address;

    @NotNull
    @Min(1)
    private Integer lanesCount;

    private String contactPhone;
    private String contactEmail;
    
    // Типы оборудования в клубе
    private List<ClubEquipmentTypeDTO> equipmentTypes;
}

