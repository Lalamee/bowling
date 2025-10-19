package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApproveRejectRequestDTO {
	@Size(max = 1000)
	private String managerNotes;

	@Size(max = 1000)
	private String rejectionReason;
} 