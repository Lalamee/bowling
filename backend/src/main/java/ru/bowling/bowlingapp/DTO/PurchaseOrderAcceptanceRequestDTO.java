package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
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

    @NotBlank
    private String supplierInn;

    private String supplierName;

    private String supplierContactPerson;

    private String supplierPhone;

    private String supplierEmail;

    private Boolean supplierVerified;

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

        private String storageLocation;

        private String shelfCode;

        private String cellCode;

        private String placementNotes;
    }
}
