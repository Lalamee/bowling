package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PartDto {

    private Long id;
    private String officialNameEn;
    private String officialNameRu;
    private String commonName;
    private String description;
    private String catalogNumber;
    private Integer quantity;
    private String location;

}
