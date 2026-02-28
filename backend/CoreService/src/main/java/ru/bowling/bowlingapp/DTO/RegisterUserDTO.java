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
    private Integer roleId; // см. таблицу role: ADMIN, MECHANIC, HEAD_MECHANIC, CLUB_OWNER

    @NotNull
    private Integer accountTypeId; // см. таблицу account_type: INDIVIDUAL, CLUB_OWNER, CLUB_MANAGER, FREE_MECHANIC_*, MAIN_ADMIN
}

