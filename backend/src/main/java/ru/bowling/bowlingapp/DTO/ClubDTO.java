package ru.bowling.bowlingapp.DTO;

import lombok.Data;

@Data
public class ClubDTO {
    private Long id;
    private String name;
    private String address;
    private Integer lanesCount;
    private String equipmentType;
}
