package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.RequestPart;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class NotificationServiceTest {

    private NotificationService notificationService;

    @BeforeEach
    void setUp() {
        notificationService = new NotificationService();
        notificationService.clearNotifications();
    }

    @Test
    void helpRequestCreatesNotificationsForAdminsManagersAndMechanic() {
        MaintenanceRequest request = MaintenanceRequest.builder()
                .requestId(10L)
                .requestDate(LocalDateTime.now())
                .build();
        RequestPart part = RequestPart.builder()
                .partId(5L)
                .partName("Датчик")
                .quantity(1)
                .status(PartStatus.APPROVAL_PENDING)
                .build();

        NotificationEvent event = notificationService.notifyHelpRequested(request, List.of(part), "Нужно оборудование");

        assertThat(event.getType()).isNotNull();
        assertThat(notificationService.getNotificationsForRole(RoleName.ADMIN))
                .extracting(NotificationEvent::getType)
                .contains(event.getType());
        assertThat(notificationService.getNotificationsForRole(RoleName.MECHANIC))
                .extracting(NotificationEvent::getRequestId)
                .contains(10L);
    }

    @Test
    void helpDecisionCreatesFollowUpNotifications() {
        MaintenanceRequest request = MaintenanceRequest.builder()
                .requestId(11L)
                .build();
        RequestPart part = RequestPart.builder().partId(6L).build();

        notificationService.notifyHelpConfirmed(request, List.of(part), "Подтверждено");
        notificationService.notifyHelpDeclined(request, List.of(part), "Нет деталей");

        List<NotificationEvent> mechanicFeed = notificationService.getNotificationsForRole(RoleName.MECHANIC);
        Set<ru.bowling.bowlingapp.DTO.NotificationEventType> types = mechanicFeed.stream()
                .map(NotificationEvent::getType)
                .collect(java.util.stream.Collectors.toSet());

        assertThat(types).contains(ru.bowling.bowlingapp.DTO.NotificationEventType.MECHANIC_HELP_CONFIRMED);
        assertThat(types).contains(ru.bowling.bowlingapp.DTO.NotificationEventType.MECHANIC_HELP_DECLINED);
    }
}
