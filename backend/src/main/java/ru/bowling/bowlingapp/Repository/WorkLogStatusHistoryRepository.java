package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.WorkLogStatusHistory;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkLogStatusHistoryRepository extends JpaRepository<WorkLogStatusHistory, Long> {

    // Поиск по журналу работ
    List<WorkLogStatusHistory> findByWorkLogLogIdOrderByChangedDateDesc(Long workLogId);

    // Поиск по старому статусу
    List<WorkLogStatusHistory> findByPreviousStatusOrderByChangedDateDesc(WorkLogStatus previousStatus);

    // Поиск по новому статусу
    List<WorkLogStatusHistory> findByNewStatusOrderByChangedDateDesc(WorkLogStatus newStatus);

    // Поиск по пользователю, изменившему статус
    List<WorkLogStatusHistory> findByChangedByUserIdOrderByChangedDateDesc(Long userId);

    // Поиск по периоду изменения
    List<WorkLogStatusHistory> findByChangedDateBetweenOrderByChangedDateDesc(LocalDateTime startDate, LocalDateTime endDate);

    // Поиск по комбинации статусов
    List<WorkLogStatusHistory> findByPreviousStatusAndNewStatusOrderByChangedDateDesc(WorkLogStatus previousStatus, WorkLogStatus newStatus);

    // Поиск последнего изменения для конкретного журнала работ
    WorkLogStatusHistory findTopByWorkLogLogIdOrderByChangedDateDesc(Long workLogId);

    // Статистические методы
    long countByNewStatus(WorkLogStatus newStatus);
    long countByPreviousStatus(WorkLogStatus previousStatus);
    long countByChangedByUserId(Long userId);
    long countByChangedDateBetween(LocalDateTime startDate, LocalDateTime endDate);
}
