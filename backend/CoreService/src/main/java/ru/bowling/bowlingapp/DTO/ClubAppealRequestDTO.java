package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClubAppealRequestDTO {
    private Long clubId;
    private NotificationEventType type;
    private String message;
    private Long requestId;
}
