package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MaintenanceRequestUpdateDTO {

    private Integer laneNumber;

    private String managerNotes;

    private String status;

    private List<PartUpdateDTO> requestedParts;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class PartUpdateDTO {

        private Long partId;

        private Long inventoryId;

        private Long catalogId;

        private String catalogNumber;

        private String partName;

        private Integer quantity;

        private Integer warehouseId;

        private String location;
    }
}
