package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoDTO {
	private Long id;
	private String phone;
	private Long roleId;
	private Long accountTypeId;
	private Boolean isVerified;
	private LocalDate registrationDate;
} 