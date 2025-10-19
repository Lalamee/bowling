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
public class WorkLogDTO {

    private Long logId;

    private Long maintenanceRequestId;

    @NotNull(message = "Club ID is required")
    private Long clubId;
    
    private String clubName;

    @Min(value = 1, message = "Lane number must be greater than 0")
    private Integer laneNumber;

    private Long equipmentId;

    @NotNull(message = "Mechanic ID is required")
    private Long mechanicId;
    
    private String mechanicName;

    private LocalDateTime createdDate;
    private LocalDateTime startedDate;
    private LocalDateTime completedDate;

    @NotNull(message = "Status is required")
    private String status;

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

    @DecimalMin(value = "0.0", message = "Actual hours must be non-negative")
    private Double actualHours;

    @DecimalMin(value = "0.0", message = "Labor cost must be non-negative")
    private Double laborCost;

    @DecimalMin(value = "0.0", message = "Total parts cost must be non-negative")
    private Double totalPartsCost;

    private Double totalCost;

    @Min(value = 1, message = "Priority must be between 1 and 5")
    @Max(value = 5, message = "Priority must be between 1 and 5")
    private Integer priority;

    private Long approvedBy;
    private String approvedByName;
    private LocalDateTime approvalDate;

    @Size(max = 2000, message = "Manager notes cannot exceed 2000 characters")
    private String managerNotes;

    @Min(value = 1, message = "Quality rating must be between 1 and 10")
    @Max(value = 10, message = "Quality rating must be between 1 and 10")
    private Integer qualityRating;

    @Min(value = 1, message = "Customer satisfaction must be between 1 and 10")
    @Max(value = 10, message = "Customer satisfaction must be between 1 and 10")
    private Integer customerSatisfaction;

    private List<String> photos;

    @Min(value = 0, message = "Warranty period cannot be negative")
    private Integer warrantyPeriodMonths;

    private LocalDateTime nextServiceDate;

    private Long createdBy;
    private String createdByName;
    private Long modifiedBy;
    private String modifiedByName;
    private LocalDateTime modifiedDate;

    private Boolean isManualEdit;
    private String manualEditReason;

    private List<WorkLogPartUsageDTO> partsUsed;
    private List<WorkLogStatusHistoryDTO> statusHistory;
}
