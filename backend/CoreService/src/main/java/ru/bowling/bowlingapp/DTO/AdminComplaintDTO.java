package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminComplaintDTO {
    private Long reviewId;
    private Long supplierId;
    private Long clubId;
    private Long userId;
    private String complaintStatus;
    private Boolean complaintResolved;
    private Integer rating;
    private String comment;
    private String complaintTitle;
    private String resolutionNotes;
}
