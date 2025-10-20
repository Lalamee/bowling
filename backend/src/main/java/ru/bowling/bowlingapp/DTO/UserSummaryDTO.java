package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class UserSummaryDTO {
    Long id;
    String role;
    String name;
    String email;
    String phone;
}
