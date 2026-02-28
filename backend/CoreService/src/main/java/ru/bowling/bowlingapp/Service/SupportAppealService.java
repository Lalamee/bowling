package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.DTO.SupportAppealRequestDTO;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.UserRepository;

import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class SupportAppealService {

    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final UserClubAccessService userClubAccessService;

    @Transactional
    public NotificationEvent submitSupportAppeal(Long userId, SupportAppealRequestDTO request) {
        if (request == null || request.getMessage() == null || request.getMessage().isBlank()) {
            throw new IllegalArgumentException("Appeal message is required");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        RoleName role = user.getRole() != null ? RoleName.from(user.getRole().getName()) : null;
        Long mechanicId = user.getMechanicProfile() != null ? user.getMechanicProfile().getProfileId() : null;
        Long clubId = resolvePrimaryClubId(user, role);

        String payload = buildPayload(user, role, request.getMessage(), clubId);
        return notificationService.notifyUserAppeal(
                user,
                clubId,
                mechanicId,
                request.getSubject(),
                request.getMessage(),
                payload
        );
    }

    private Long resolvePrimaryClubId(User user, RoleName role) {
        if (user == null || role == null) {
            return null;
        }
        if (role == RoleName.CLUB_OWNER || role == RoleName.HEAD_MECHANIC) {
            List<Long> clubs = userClubAccessService.resolveAccessibleClubIds(user);
            return clubs.stream().filter(Objects::nonNull).findFirst().orElse(null);
        }
        return null;
    }

    private String buildPayload(User user, RoleName role, String message, Long clubId) {
        StringBuilder builder = new StringBuilder();
        if (user != null && user.getFullName() != null && !user.getFullName().isBlank()) {
            builder.append("Отправитель: ").append(user.getFullName().trim()).append("\n");
        }
        if (user != null && user.getPhone() != null && !user.getPhone().isBlank()) {
            builder.append("Телефон: ").append(user.getPhone().trim()).append("\n");
        }
        if (role != null) {
            builder.append("Роль: ").append(role.name()).append("\n");
        }
        if (clubId != null) {
            builder.append("Клуб: ").append(clubId).append("\n");
        }
        builder.append("Сообщение:\n").append(message.trim());
        return builder.toString();
    }
}
