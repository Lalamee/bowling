package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ClubCreateDTO {

    @NotBlank
    private String name;

    @NotBlank
    private String address;

    private Integer lanesCount;

    private String contactPhone;

    private String contactEmail;
}
