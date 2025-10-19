package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ServiceHistoryDTO {

    private Long serviceId;

    @NotNull(message = "Club ID is required")
    private Long clubId;
    private String clubName;

    private Long equipmentId;
    private String equipmentName;

    @Min(value = 1, message = "Lane number must be greater than 0")
    private Integer laneNumber;

    @NotNull(message = "Service type is required")
    private String serviceType;

    private LocalDateTime serviceDate;

    @NotBlank(message = "Description is required")
    @Size(max = 5000, message = "Description cannot exceed 5000 characters")
    private String description;

    @Size(max = 2000, message = "Parts replaced description cannot exceed 2000 characters")
    private String partsReplaced;

    @DecimalMin(value = "0.0", message = "Labor hours must be non-negative")
    private Double laborHours;

    private Double totalCost;

    @NotNull(message = "Performed by mechanic ID is required")
    private Long performedByMechanicId;
    private String performedByMechanicName;

    private Long supervisedByUserId;
    private String supervisedByUserName;

    private LocalDateTime nextServiceDue;
    private LocalDateTime warrantyUntil;

    @Size(max = 2000, message = "Service notes cannot exceed 2000 characters")
    private String serviceNotes;

    private String performanceMetrics; // JSON string
    private List<String> photos;
    private List<String> documents;

    private LocalDateTime createdDate;
    private Long createdBy;
    private String createdByName;

    private List<ServiceHistoryPartDTO> partsUsed;
}
