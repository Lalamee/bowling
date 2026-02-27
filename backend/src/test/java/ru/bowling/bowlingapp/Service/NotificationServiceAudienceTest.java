package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class NotificationServiceAudienceTest {

    private NotificationService notificationService;

    @BeforeEach
    void setUp() {
        notificationService = new NotificationService(new MockNotificationWebSocketPublisher());
        notificationService.clearNotifications();
    }

    @Test
    void shouldFilterNotificationsByClubAndMechanic() {
        MechanicProfile mechanicProfile = new MechanicProfile();
        mechanicProfile.setProfileId(77L);

        User user = User.builder()
                .role(role("MECHANIC"))
                .mechanicProfile(mechanicProfile)
                .build();

        notificationService.notifyAdminResponseToMechanic(77L, "ok", "payload");
        notificationService.notifyAdminResponseToMechanic(99L, "wrong", "payload");

        List<NotificationEvent> events = notificationService.getNotificationsForUser(user, List.of(1L, 2L));

        assertThat(events).hasSize(1);
        assertThat(events.get(0).getMechanicId()).isEqualTo(77L);
    }

    private Role role(String name) {
        Role role = new Role();
        role.setName(name);
        return role;
    }
}
