package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PasswordResetInitRequestDTO {
	@NotBlank
	@Pattern(regexp = "^\\+?\\d{10,15}$", message = "Invalid phone number")
	private String phone;
} 