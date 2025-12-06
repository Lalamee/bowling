package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Value;
import ru.bowling.bowlingapp.Enum.RoleName;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Value
@Builder(toBuilder = true)
public class NotificationEvent {
    UUID id;
    NotificationEventType type;
    String message;
    Long requestId;
    Long workLogId;
    Long mechanicId;
    Long clubId;
    List<Long> partIds;
    String payload;
    LocalDateTime createdAt;
    Set<RoleName> audiences;
}
