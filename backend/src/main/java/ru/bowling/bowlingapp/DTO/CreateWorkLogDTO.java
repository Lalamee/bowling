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
public class CreateWorkLogDTO {

    private Long maintenanceRequestId;

    @NotNull(message = "Club ID is required")
    private Long clubId;

    @Min(value = 1, message = "Lane number must be greater than 0")
    private Integer laneNumber;

    private Long equipmentId;

    @NotNull(message = "Mechanic ID is required")
    private Long mechanicId;

    @NotNull(message = "Work type is required")
    private String workType;

    @NotBlank(message = "Problem description is required")
    @Size(max = 5000, message = "Problem description cannot exceed 5000 characters")
    private String problemDescription;

    @Size(max = 5000, message = "Work performed description cannot exceed 5000 characters")
    private String workPerformed;

    @Size(max = 5000, message = "Solution description cannot exceed 5000 characters")
    private String solutionDescription;

    @DecimalMin(value = "0.0", message = "Estimated hours must be non-negative")
    private Double estimatedHours;

    @DecimalMin(value = "0.0", message = "Labor cost must be non-negative")
    private Double laborCost;

    @Builder.Default
    @Min(value = 1, message = "Priority must be between 1 and 5")
    @Max(value = 5, message = "Priority must be between 1 and 5")
    private Integer priority = 3; // Средний приоритет по умолчанию

    @Size(max = 2000, message = "Manager notes cannot exceed 2000 characters")
    private String managerNotes;

    @Min(value = 0, message = "Warranty period cannot be negative")
    private Integer warrantyPeriodMonths;

    private LocalDateTime nextServiceDate;

    private List<String> photos;

    private List<WorkLogPartUsageDTO> partsUsed;
}
