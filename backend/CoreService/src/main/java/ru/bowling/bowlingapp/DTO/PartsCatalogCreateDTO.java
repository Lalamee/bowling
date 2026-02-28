package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PartsCatalogCreateDTO {

    @NotBlank
    private String catalogNumber;

    private String name;

    private String description;

    private String categoryCode;

    private Boolean isUnique;
}
