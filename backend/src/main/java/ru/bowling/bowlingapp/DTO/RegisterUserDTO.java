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
    private Integer roleId; // см. таблицу role: 1 = ADMIN, 4 = MECHANIC, 5 = CLUB_OWNER, 6 = HEAD_MECHANIC

    @NotNull
    private Integer accountTypeId; // см. таблицу account_type: 1 = INDIVIDUAL, 2 = CLUB_OWNER
}

