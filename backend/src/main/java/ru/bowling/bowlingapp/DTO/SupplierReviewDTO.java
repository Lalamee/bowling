package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierReviewDTO {
    private Long reviewId;
    private Integer rating;
    private String comment;
    private boolean complaint;
    private SupplierComplaintStatus complaintStatus;
    private Boolean complaintResolved;
    private String complaintTitle;
    private String resolutionNotes;
    private LocalDateTime createdAt;
}
