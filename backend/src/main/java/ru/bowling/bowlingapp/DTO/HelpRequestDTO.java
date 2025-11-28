package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

@Data
public class HelpRequestDTO {

    @NotEmpty(message = "Нужно выбрать хотя бы одну позицию")
    private List<Long> partIds;

    private String reason;
}
