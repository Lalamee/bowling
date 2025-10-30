package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequestDTO {
    @Valid
    @NotNull
    private RegisterUserDTO user;

    @Valid
    private MechanicProfileDTO mechanicProfile;

    @Valid
    private ManagerProfileDTO managerProfile;

    @Valid
    private OwnerProfileDTO ownerProfile;

    @Valid
    private BowlingClubDTO club;
}
