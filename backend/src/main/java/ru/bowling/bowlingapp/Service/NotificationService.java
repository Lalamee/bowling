package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {
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
