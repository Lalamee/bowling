package ru.bowling.bowlingapp.Service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.DTO.NotificationEventType;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Enum.RoleName;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

@Slf4j
@Service
public class NotificationService {
    private final CopyOnWriteArrayList<NotificationEvent> notifications = new CopyOnWriteArrayList<>();

    public List<NotificationEvent> getNotificationsForRole(RoleName role) {
        if (role == null) {
            return List.of();
        }
        return notifications.stream()
                .filter(event -> event.getAudiences() != null && event.getAudiences().contains(role))
                .collect(Collectors.toList());
    }

    public List<NotificationEvent> getNotificationsForUser(User user, List<Long> accessibleClubIds) {
        if (user == null || user.getRole() == null) {
            return List.of();
        }
        RoleName role = RoleName.from(user.getRole().getName());
        Long mechanicProfileId = user.getMechanicProfile() != null ? user.getMechanicProfile().getProfileId() : null;
        List<Long> clubs = accessibleClubIds != null ? accessibleClubIds : List.of();

        return notifications.stream()
                .filter(event -> event.getAudiences() != null && event.getAudiences().contains(role))
                .filter(event -> event.getClubId() == null || clubs.contains(event.getClubId()))
                .filter(event -> event.getMechanicId() == null || Objects.equals(event.getMechanicId(), mechanicProfileId))
                .collect(Collectors.toList());
    }

    public void clearNotifications() {
        notifications.clear();
    }

    public NotificationEvent notifyFreeMechanicPending(MechanicProfile mechanicProfile) {
        if (mechanicProfile == null || mechanicProfile.getUser() == null) {
            return null;
        }

        NotificationEvent event = NotificationEvent.builder()
                .id(UUID.randomUUID())
                .type(NotificationEventType.FREE_MECHANIC_PENDING)
                .message("Свободный механик ожидает подтверждения")
                .mechanicId(mechanicProfile.getProfileId())
                .payload(mechanicProfile.getFullName())
                .createdAt(LocalDateTime.now())
                .audiences(Set.of(RoleName.ADMIN))
                .build();
        notifications.add(event);

        log.info("NOTIFICATION: Свободный механик {} ожидает подтверждения администрацией (user {})",
                mechanicProfile.getProfileId(), mechanicProfile.getUser().getUserId());
        return event;
    }

    public NotificationEvent notifyHelpRequested(
            MaintenanceRequest request,
            List<RequestPart> parts,
            String reason
    ) {
        String message = "Механик не может выполнить работы самостоятельно (запрос помощи)";
        NotificationEvent event = buildBaseEvent(
                NotificationEventType.MECHANIC_HELP_REQUESTED,
                message,
                request,
                parts,
                reason,
                Set.of(RoleName.ADMIN, RoleName.HEAD_MECHANIC, RoleName.CLUB_OWNER, RoleName.MECHANIC)
        );
        notifications.add(event);
        log.info("NOTIFICATION: {}. Request #{}, parts={}, reason={}", message, request != null ? request.getRequestId() : null, partIds(parts), reason);
        return event;
    }

    public NotificationEvent notifyHelpConfirmed(MaintenanceRequest request, List<RequestPart> parts, String comment) {
        NotificationEvent event = buildBaseEvent(
                NotificationEventType.MECHANIC_HELP_CONFIRMED,
                "Запрос помощи подтвержден",
                request,
                parts,
                comment,
                Set.of(RoleName.MECHANIC, RoleName.ADMIN, RoleName.HEAD_MECHANIC, RoleName.CLUB_OWNER)
        );
        notifications.add(event);
        log.info("NOTIFICATION: Запрос помощи подтвержден по заявке #{}: {}", request != null ? request.getRequestId() : null, comment);
        return event;
    }

    public NotificationEvent notifyHelpDeclined(MaintenanceRequest request, List<RequestPart> parts, String comment) {
        NotificationEvent event = buildBaseEvent(
                NotificationEventType.MECHANIC_HELP_DECLINED,
                "Запрос помощи отклонен",
                request,
                parts,
                comment,
                Set.of(RoleName.MECHANIC, RoleName.ADMIN, RoleName.HEAD_MECHANIC, RoleName.CLUB_OWNER)
        );
        notifications.add(event);
        log.info("NOTIFICATION: Запрос помощи отклонен по заявке #{}: {}", request != null ? request.getRequestId() : null, comment);
        return event;
    }

    public NotificationEvent notifyHelpReassigned(MaintenanceRequest request, List<RequestPart> parts, Long newMechanicId, String comment) {
        NotificationEvent event = buildBaseEvent(
                NotificationEventType.MECHANIC_HELP_REASSIGNED,
                "Назначен другой специалист для заявки",
                request,
                parts,
                comment,
                Set.of(RoleName.MECHANIC, RoleName.ADMIN, RoleName.HEAD_MECHANIC, RoleName.CLUB_OWNER)
        ).toBuilder()
                .mechanicId(newMechanicId)
                .build();
        notifications.add(event);
        log.info("NOTIFICATION: Заявка #{} переназначена другому механику {}: {}", request != null ? request.getRequestId() : null, newMechanicId, comment);
        return event;
    }

    private NotificationEvent buildBaseEvent(NotificationEventType type,
                                             String message,
                                             MaintenanceRequest request,
                                             List<RequestPart> parts,
                                             String payload,
                                             Set<RoleName> audiences) {
        return NotificationEvent.builder()
                .id(UUID.randomUUID())
                .type(type)
                .message(message)
                .requestId(request != null ? request.getRequestId() : null)
                .mechanicId(request != null && request.getMechanic() != null ? request.getMechanic().getProfileId() : null)
                .clubId(request != null && request.getClub() != null ? request.getClub().getClubId() : null)
                .partIds(partIds(parts))
                .payload(payload)
                .createdAt(LocalDateTime.now())
                .audiences(audiences)
                .build();
    }

    private List<Long> partIds(List<RequestPart> parts) {
        if (parts == null) {
            return new ArrayList<>();
        }
        return parts.stream()
                .filter(p -> p != null && p.getPartId() != null)
                .map(RequestPart::getPartId)
                .collect(Collectors.toList());
    }
    public void notifyMaintenanceRequestCreated(
            MaintenanceRequest request,
            List<OwnerProfile> owners,
            List<ManagerProfile> managers
    ) {
        if (request == null) {
            return;
        }

        BowlingClub club = request.getClub();
        String clubName = club != null ? club.getName() : "Неизвестный клуб";
        String mechanicName = request.getMechanic() != null ? request.getMechanic().getFullName() : "Неизвестный механик";

        log.info("NOTIFICATION: Новая заявка на обслуживание #{} для клуба {} (дорожка {}), механик: {}", request.getRequestId(), clubName, request.getLaneNumber(), mechanicName);

        if (owners != null && !owners.isEmpty()) {
            for (OwnerProfile owner : owners) {
                if (owner == null) {
                    continue;
                }
                String ownerName = owner.getContactPerson() != null && !owner.getContactPerson().isBlank()
                        ? owner.getContactPerson()
                        : Optional.ofNullable(owner.getLegalName()).filter(name -> !name.isBlank()).orElse("Владелец клуба");
                String ownerPhone = owner.getUser() != null ? owner.getUser().getPhone() : owner.getContactPhone();
                String ownerClub = owner.getClubs() != null && !owner.getClubs().isEmpty()
                        ? owner.getClubs().get(0).getName()
                        : clubName;
                log.info("NOTIFICATION -> Owner {} ({}) уведомлен о заявке #{} (клуб: {})",
                        ownerName,
                        ownerPhone != null ? ownerPhone : "—",
                        request.getRequestId(),
                        ownerClub);
            }
        } else {
            log.info("NOTIFICATION: Нет владельцев для уведомления по заявке #{}", request.getRequestId());
        }

        if (managers != null && !managers.isEmpty()) {
            for (ManagerProfile manager : managers) {
                if (manager == null) {
                    continue;
                }
                String managerName = manager.getFullName() != null && !manager.getFullName().isBlank()
                        ? manager.getFullName()
                        : "Менеджер";
                User managerUser = manager.getUser();
                String contact = managerUser != null && managerUser.getPhone() != null
                        ? managerUser.getPhone()
                        : manager.getContactPhone();
                String managerClub = manager.getClub() != null ? manager.getClub().getName() : clubName;
                log.info("NOTIFICATION -> Manager {} ({}) уведомлен о заявке #{} (клуб: {})",
                        managerName,
                        contact != null ? contact : "—",
                        request.getRequestId(),
                        managerClub);
            }
        } else {
            log.info("NOTIFICATION: Для клубов механика и заявки нет назначенных менеджеров для уведомления по заявке #{}",
                    request.getRequestId());
        }
    }

    public void notifyWorkLogCreated(WorkLog workLog) {
        log.info("NOTIFICATION: Создан журнал работ #{} для клуба {} (дорожка {})",
                workLog.getLogId(),
                workLog.getClub().getName(),
                workLog.getLaneNumber());
    }

    public void notifyWorkLogStatusChanged(WorkLog workLog, WorkLogStatus previousStatus, WorkLogStatus newStatus) {
        log.info("NOTIFICATION: Изменен статус журнала работ #{} с {} на {}", 
                workLog.getLogId(), previousStatus, newStatus);

        String message = buildStatusChangeMessage(workLog, previousStatus, newStatus);

        switch (newStatus) {
            case ASSIGNED:
                notifyMechanicAssigned(workLog);
                break;
            case COMPLETED:
                notifyWorkCompleted(workLog);
                break;
            case VERIFIED:
                notifyWorkVerified(workLog);
                break;
            case CLOSED:
                notifyWorkClosed(workLog);
                break;
            default:
                log.debug("No specific notification handler for status: {}", newStatus);
        }
    }

    public void notifyWorkLogAssigned(WorkLog workLog, MechanicProfile mechanic) {
        log.info("NOTIFICATION: Работа #{} назначена механику {} ({})", 
                workLog.getLogId(),
                mechanic.getFullName(),
                mechanic.getUser().getPhone());
    }

    public void notifyServiceRecordCreated(ServiceHistory serviceHistory) {
        log.info("NOTIFICATION: Создана запись об обслуживании #{} для оборудования {}", 
                serviceHistory.getServiceId(),
                serviceHistory.getEquipment() != null ? serviceHistory.getEquipment().getEquipmentId() : "N/A");
    }

    public void notifyMaintenanceRequestUpdated(Long requestId, String status) {
        log.info("NOTIFICATION: Обновлена заявка на обслуживание #{}, новый статус: {}", 
                requestId, status);
    }

    public void notifyPartsUsed(WorkLog workLog, String partsCatalogNumbers) {
        log.info("NOTIFICATION: Использованы запчасти {} для работы #{}", 
                partsCatalogNumbers, workLog.getLogId());
    }

    public void notifyHighPriorityWork(WorkLog workLog) {
        log.warn("NOTIFICATION: ВЫСОКИЙ ПРИОРИТЕТ! Работа #{} требует немедленного внимания. " +
                "Клуб: {}, Дорожка: {}, Приоритет: {}", 
                workLog.getLogId(),
                workLog.getClub().getName(),
                workLog.getLaneNumber(),
                workLog.getPriority());
    }

    public void notifyServiceDue(ServiceHistory serviceHistory, int daysUntilDue) {
        log.info("NOTIFICATION: Приближается срок планового обслуживания! " +
                "Оборудование: {}, Дней до обслуживания: {}", 
                serviceHistory.getEquipment() != null ? serviceHistory.getEquipment().getEquipmentId() : "N/A",
                daysUntilDue);
    }

    public void notifyWarrantyExpiring(ServiceHistory serviceHistory, int daysUntilExpiry) {
        log.info("NOTIFICATION: Истекает гарантия! " +
                "Обслуживание: {}, Дней до окончания гарантии: {}", 
                serviceHistory.getServiceId(), daysUntilExpiry);
    }

    public void notifyInventoryLow(String catalogNumber, int currentQuantity, int minQuantity) {
        log.warn("NOTIFICATION: НИЗКИЙ ОСТАТОК НА СКЛАДЕ! " +
                "Запчасть: {}, Остаток: {}, Минимум: {}", 
                catalogNumber, currentQuantity, minQuantity);
    }

    private void notifyMechanicAssigned(WorkLog workLog) {
        if (workLog.getMechanic() != null) {
            log.info("Sending assignment notification to mechanic: {}", workLog.getMechanic().getFullName());
        }
    }

    private void notifyWorkCompleted(WorkLog workLog) {
        log.info("Sending completion notification for work log: {}", workLog.getLogId());
    }

    private void notifyWorkVerified(WorkLog workLog) {
        log.info("Sending verification notification for work log: {}", workLog.getLogId());
    }

    private void notifyWorkClosed(WorkLog workLog) {
        log.info("Sending closure notification for work log: {}", workLog.getLogId());
    }

    private String buildStatusChangeMessage(WorkLog workLog, WorkLogStatus previousStatus, WorkLogStatus newStatus) {
        return String.format("Работа #%d: статус изменен с '%s' на '%s'", 
                workLog.getLogId(), 
                previousStatus != null ? previousStatus.name() : "НЕТ", 
                newStatus.name());
    }
}
