package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AddRequestPartsDTO {

    @Valid
    @NotEmpty(message = "At least one part is required")
    private List<PartRequestDTO.RequestedPartDTO> requestedParts;
}
