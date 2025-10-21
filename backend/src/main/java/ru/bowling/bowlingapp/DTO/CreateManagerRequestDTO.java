package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateManagerRequestDTO {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Phone is required")
    @Pattern(regexp = "^\\+?[0-9\\s\-()]{10,20}$", message = "Invalid phone format")
    private String phone;

    @Email(message = "Invalid email format")
    private String email;

    @Size(min = 6, max = 32, message = "Password must be between 6 and 32 characters")
    private String password;
}
