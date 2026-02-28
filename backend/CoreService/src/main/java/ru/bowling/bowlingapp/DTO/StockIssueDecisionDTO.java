package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockIssueDecisionDTO {

        @Size(max = 1000)
        private String managerNotes;

        @Valid
        @NotEmpty(message = "Необходимо передать хотя бы одно решение по позиции")
        private List<PartDecisionDTO> partDecisions;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class PartDecisionDTO {
                @NotNull(message = "Идентификатор позиции обязателен")
                private Long partId;

                @NotNull(message = "Укажите согласованное количество")
                @Min(value = 0, message = "Количество не может быть отрицательным")
                private Integer approvedQuantity;

                @Size(max = 500)
                private String managerComment;
        }
}
