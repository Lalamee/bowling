package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {
    public void notifyMaintenanceRequestCreated(
            MaintenanceRequest request,
            List<OwnerProfile> owners,
            List<ManagerProfile> managers,
            List<AdministratorProfile> administrators
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

        if (administrators != null && !administrators.isEmpty()) {
            for (AdministratorProfile administrator : administrators) {
                if (administrator == null) {
                    continue;
                }
                String adminName = administrator.getFullName() != null && !administrator.getFullName().isBlank()
                        ? administrator.getFullName()
                        : "Администратор клуба";
                User adminUser = administrator.getUser();
                String contact = adminUser != null && adminUser.getPhone() != null
                        ? adminUser.getPhone()
                        : administrator.getContactPhone();
                String adminClub = administrator.getClub() != null ? administrator.getClub().getName() : clubName;
                log.info("NOTIFICATION -> Administrator {} ({}) уведомлен о заявке #{} (клуб: {})",
                        adminName,
                        contact != null ? contact : "—",
                        request.getRequestId(),
                        adminClub);
            }
        } else {
            log.info("NOTIFICATION: Администраторы не найдены для уведомления по заявке #{}", request.getRequestId());
        }
    }

    public void notifyMaintenanceRequestStatusChanged(
            MaintenanceRequest request,
            MaintenanceRequestStatus previousStatus,
            MaintenanceRequestStatus newStatus,
            List<OwnerProfile> owners,
            List<ManagerProfile> managers,
            List<AdministratorProfile> administrators
    ) {
        if (request == null) {
            return;
        }

        BowlingClub club = request.getClub();
        String clubName = club != null ? club.getName() : "Неизвестный клуб";
        log.info("NOTIFICATION: Заявка на обслуживание #{} в клубе {} изменила статус с {} на {}",
                request.getRequestId(),
                clubName,
                previousStatus != null ? previousStatus.name() : "—",
                newStatus != null ? newStatus.name() : "—");

        if (owners != null && !owners.isEmpty()) {
            for (OwnerProfile owner : owners) {
                if (owner == null) {
                    continue;
                }
                String ownerName = owner.getContactPerson() != null && !owner.getContactPerson().isBlank()
                        ? owner.getContactPerson()
                        : Optional.ofNullable(owner.getLegalName()).filter(name -> !name.isBlank()).orElse("Владелец клуба");
                String ownerPhone = owner.getUser() != null ? owner.getUser().getPhone() : owner.getContactPhone();
                log.info("NOTIFICATION -> Owner {} ({}) получил обновление статуса заявки #{}: {}",
                        ownerName,
                        ownerPhone != null ? ownerPhone : "—",
                        request.getRequestId(),
                        newStatus != null ? newStatus.name() : "—");
            }
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
                log.info("NOTIFICATION -> Manager {} ({}) получил обновление статуса заявки #{}: {}",
                        managerName,
                        contact != null ? contact : "—",
                        request.getRequestId(),
                        newStatus != null ? newStatus.name() : "—");
            }
        }

        if (administrators != null && !administrators.isEmpty()) {
            for (AdministratorProfile administrator : administrators) {
                if (administrator == null) {
                    continue;
                }
                String adminName = administrator.getFullName() != null && !administrator.getFullName().isBlank()
                        ? administrator.getFullName()
                        : "Администратор клуба";
                User adminUser = administrator.getUser();
                String contact = adminUser != null && adminUser.getPhone() != null
                        ? adminUser.getPhone()
                        : administrator.getContactPhone();
                log.info("NOTIFICATION -> Administrator {} ({}) получил обновление статуса заявки #{}: {}",
                        adminName,
                        contact != null ? contact : "—",
                        request.getRequestId(),
                        newStatus != null ? newStatus.name() : "—");
            }
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
