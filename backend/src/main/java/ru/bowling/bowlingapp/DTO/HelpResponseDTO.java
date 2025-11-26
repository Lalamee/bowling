package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class HelpResponseDTO {

    public enum Decision {
        APPROVED,
        REASSIGNED,
        DECLINED
    }

    @NotEmpty(message = "Нужно выбрать хотя бы одну позицию")
    private List<Long> partIds;

    @NotNull(message = "Решение обязательно")
    private Decision decision;

    private Long reassignedMechanicId;

    private String comment;
}
