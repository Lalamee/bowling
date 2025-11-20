package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ClubStaffMemberDTO {
    private Long userId;
    private String fullName;
    private String phone;
    private String email;
    private String role;
    private Boolean isActive;
    // Показатель, что владелец ограничил доступ механика к данным клуба
    private Boolean accessRestricted;
}
