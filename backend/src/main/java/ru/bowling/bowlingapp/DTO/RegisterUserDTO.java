package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterUserDTO {
    @NotBlank
    private String phone;

    @NotBlank
    @Size(min = 8)
    private String password;

    @NotNull
    private Integer roleId; // 1 = механик, 2 = гл. механик, 3 = владелец

    @NotNull
    private Integer accountTypeId; // 1 = физлицо, 2 = владелец клуба
}

