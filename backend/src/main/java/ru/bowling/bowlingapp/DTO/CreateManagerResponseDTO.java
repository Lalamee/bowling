package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CreateManagerResponseDTO {
    private Long userId;
    private String fullName;
    private String phone;
    private String password;
    private String role;
}
