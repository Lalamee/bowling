package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PasswordResetConfirmRequestDTO {
	@NotBlank
	private String token;

	@NotBlank
	@Size(min = 8, message = "Password must be at least 8 characters long")
	private String newPassword;
} 