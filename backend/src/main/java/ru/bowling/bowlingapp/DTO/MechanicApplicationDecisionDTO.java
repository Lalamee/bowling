package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MechanicApplicationDecisionDTO {
    @NotBlank
    private String targetAccountType;

    private String comment;
}

