package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ManagerProfileDTO {
    @NotBlank
    private String fullName;

    @Email(message = "Invalid email format")
    private String contactEmail;

    private String contactPhone;

    @NotNull(message = "Club selection is required for manager profile")
    private Long clubId;
}
