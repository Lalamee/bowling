package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CreateStaffRequestDTO {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Phone is required")
    @Pattern(regexp = "^\\+?[0-9\\s\\-()]{10,20}$", message = "Invalid phone format")
    private String phone;

    @Email(message = "Invalid email format")
    private String email;

    private String password;

    @NotBlank(message = "Role is required")
    private String role;
}
