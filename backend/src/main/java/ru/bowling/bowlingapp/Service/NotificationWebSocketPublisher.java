package ru.bowling.bowlingapp.Service;

import ru.bowling.bowlingapp.DTO.NotificationEvent;

public interface NotificationWebSocketPublisher {
    void publishNotification(NotificationEvent event);

    void publishTestBroadcast(String message);
}
