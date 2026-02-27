package ru.bowling.bowlingapp.integration.onec.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OneCProductDto {
    private String catalogNumber;
    private String nameRu;
    private String nameEn;
    private String description;
}
