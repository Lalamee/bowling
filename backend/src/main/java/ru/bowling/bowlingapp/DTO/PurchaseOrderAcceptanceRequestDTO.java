package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseOrderAcceptanceRequestDTO {
    @NotEmpty
    @Valid
    private List<PartAcceptanceDTO> parts;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PartAcceptanceDTO {
        @NotNull
        private Long partId;

        @NotNull
        private PartStatus status;

        @Min(0)
        private Integer acceptedQuantity;

        private String comment;
    }
}
