package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.NotificationBroadcastRequest;
import ru.bowling.bowlingapp.Service.NotificationWebSocketPublisher;

import java.util.Map;

@RestController
@RequestMapping("/api/public/ws/notifications")
@RequiredArgsConstructor
public class NotificationWebSocketController {

    private final NotificationWebSocketPublisher notificationWebSocketPublisher;

    @MessageMapping("/notifications.broadcast")
    public void broadcastFromStomp(@Payload NotificationBroadcastRequest request) {
        notificationWebSocketPublisher.publishTestBroadcast(request != null ? request.getMessage() : null);
    }

    @PostMapping("/broadcast")
    public Map<String, String> broadcastFromRest(@RequestBody(required = false) NotificationBroadcastRequest request) {
        notificationWebSocketPublisher.publishTestBroadcast(request != null ? request.getMessage() : null);
        return Map.of("status", "sent");
    }
}
