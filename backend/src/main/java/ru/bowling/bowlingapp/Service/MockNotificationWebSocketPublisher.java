package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.NotificationEvent;

@Slf4j
@Service
@RequiredArgsConstructor
public class MockNotificationWebSocketPublisher implements NotificationWebSocketPublisher {

    private final SimpMessagingTemplate messagingTemplate;

    @Override
    public void publishNotification(NotificationEvent event) {
        if (event == null) {
            return;
        }
        messagingTemplate.convertAndSend("/topic/notifications", event);
        log.debug("Mock WebSocket publish to /topic/notifications: {}", event.getId());
    }

    @Override
    public void publishTestBroadcast(String message) {
        String payload = (message == null || message.isBlank())
                ? "Тестовое WebSocket-уведомление"
                : message.trim();
        messagingTemplate.convertAndSend("/topic/notifications/test", payload);
        log.info("Mock WebSocket test broadcast sent: {}", payload);
    }
}
