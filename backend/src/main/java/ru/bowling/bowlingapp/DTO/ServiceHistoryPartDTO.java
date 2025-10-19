package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ServiceHistoryPartDTO {

    private Long id;
    private Long serviceHistoryId;
    private Long partCatalogId;

    @NotBlank(message = "Part name is required")
    @Size(max = 255, message = "Part name cannot exceed 255 characters")
    private String partName;

    @NotBlank(message = "Catalog number is required")
    @Size(max = 100, message = "Catalog number cannot exceed 100 characters")
    private String catalogNumber;

    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;

    @NotNull(message = "Unit cost is required")
    @DecimalMin(value = "0.0", message = "Unit cost must be non-negative")
    private Double unitCost;

    private Double totalCost;

    @Min(value = 0, message = "Warranty period cannot be negative")
    private Integer warrantyMonths;

    private Long supplierId;
    private String supplierName;

    @Size(max = 1000, message = "Installation notes cannot exceed 1000 characters")
    private String installationNotes;

    private LocalDateTime createdDate;
}
