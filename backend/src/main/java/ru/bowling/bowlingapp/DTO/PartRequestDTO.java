package ru.bowling.bowlingapp.DTO;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartRequestDTO {

    @NotNull(message = "Club ID is required")
    private Long clubId;

    @NotNull(message = "Lane number is required")
    @Positive(message = "Lane number must be positive")
    private Integer laneNumber;

    @NotNull(message = "Mechanic ID is required")
    private Long mechanicId;

    private String managerNotes;

    @NotNull(message = "At least one part is required")
    private List<RequestedPartDTO> requestedParts;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class RequestedPartDTO {

        private Long inventoryId;

        private Long catalogId;

        private String catalogNumber;

        @NotBlank(message = "Part name is required")
        private String partName;

        @NotNull(message = "Quantity is required")
        @Positive(message = "Quantity must be positive")
        private Integer quantity;

        private Integer warehouseId;

        private String location;
    }
}
