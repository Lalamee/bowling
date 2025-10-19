package ru.bowling.bowlingapp.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.WorkLog;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkLogRepository extends JpaRepository<WorkLog, Long> {

    // Поиск по статусу
    List<WorkLog> findByStatusOrderByCreatedDateDesc(WorkLogStatus status);
    List<WorkLog> findByStatusInOrderByCreatedDateDesc(List<WorkLogStatus> statuses);

    // Поиск по механику
    List<WorkLog> findByMechanicProfileIdOrderByCreatedDateDesc(Long mechanicId);
    Page<WorkLog> findByMechanicProfileId(Long mechanicId, Pageable pageable);

    // Поиск по клубу
    List<WorkLog> findByClubClubIdOrderByCreatedDateDesc(Long clubId);
    Page<WorkLog> findByClubClubId(Long clubId, Pageable pageable);

    // Поиск по дорожке
    List<WorkLog> findByClubClubIdAndLaneNumberOrderByCreatedDateDesc(Long clubId, Integer laneNumber);

    // Поиск по оборудованию
    List<WorkLog> findByEquipmentEquipmentIdOrderByCreatedDateDesc(Long equipmentId);

    // Поиск по типу работ
    List<WorkLog> findByWorkTypeOrderByCreatedDateDesc(WorkType workType);

    // Поиск по периоду времени
    List<WorkLog> findByCreatedDateBetweenOrderByCreatedDateDesc(LocalDateTime startDate, LocalDateTime endDate);
    List<WorkLog> findByCreatedDateAfterOrderByCreatedDateDesc(LocalDateTime startDate);
    List<WorkLog> findByCreatedDateBeforeOrderByCreatedDateDesc(LocalDateTime endDate);

    // Поиск по приоритету
    List<WorkLog> findByPriorityLessThanEqualOrderByPriorityAscCreatedDateDesc(Integer priority);
    List<WorkLog> findByPriorityOrderByCreatedDateDesc(Integer priority);

    // Поиск по заявке на обслуживание
    List<WorkLog> findByMaintenanceRequestRequestIdOrderByCreatedDateDesc(Long requestId);

    // Комбинированные поиски
    List<WorkLog> findByClubClubIdAndStatusOrderByCreatedDateDesc(Long clubId, WorkLogStatus status);
    List<WorkLog> findByMechanicProfileIdAndStatusOrderByCreatedDateDesc(Long mechanicId, WorkLogStatus status);
    List<WorkLog> findByWorkTypeAndStatusOrderByCreatedDateDesc(WorkType workType, WorkLogStatus status);

    // Поиск по пользователю, создавшему запись
    List<WorkLog> findByCreatedByOrderByCreatedDateDesc(Long createdBy);

    // Поиск по датам завершения
    List<WorkLog> findByCompletedDateBetweenOrderByCompletedDateDesc(LocalDateTime startDate, LocalDateTime endDate);
    List<WorkLog> findByCompletedDateIsNotNullOrderByCompletedDateDesc();
    List<WorkLog> findByCompletedDateIsNullOrderByCreatedDateDesc();

    // Поиск по рейтингу качества
    List<WorkLog> findByQualityRatingGreaterThanEqualOrderByCreatedDateDesc(Integer rating);
    List<WorkLog> findByQualityRatingIsNotNullOrderByQualityRatingDescCreatedDateDesc();

    // Поиск по затраченным часам
    List<WorkLog> findByActualHoursGreaterThanOrderByCreatedDateDesc(Double hours);
    List<WorkLog> findByActualHoursBetweenOrderByCreatedDateDesc(Double minHours, Double maxHours);

    // Поиск по стоимости
    List<WorkLog> findByTotalCostGreaterThanOrderByCreatedDateDesc(Double cost);
    List<WorkLog> findByTotalCostBetweenOrderByCreatedDateDesc(Double minCost, Double maxCost);

    // Поиск работ с ручным редактированием
    List<WorkLog> findByIsManualEditTrueOrderByCreatedDateDesc();

    // Поиск работ с гарантией
    List<WorkLog> findByWarrantyPeriodMonthsIsNotNullOrderByCreatedDateDesc();

    // Поиск по дате следующего обслуживания
    List<WorkLog> findByNextServiceDateBeforeOrderByNextServiceDateAsc(LocalDateTime date);
    List<WorkLog> findByNextServiceDateIsNotNullOrderByNextServiceDateAsc();

    // Статистические методы
    long countByStatus(WorkLogStatus status);
    long countByWorkType(WorkType workType);
    long countByMechanicProfileId(Long mechanicId);
    long countByClubClubId(Long clubId);
    long countByCreatedDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    // Существование записей
    boolean existsByMaintenanceRequestRequestId(Long requestId);
    boolean existsByEquipmentEquipmentIdAndStatusIn(Long equipmentId, List<WorkLogStatus> statuses);

    // Поиск с пагинацией
    Page<WorkLog> findByStatusOrderByCreatedDateDesc(WorkLogStatus status, Pageable pageable);
    Page<WorkLog> findByWorkTypeOrderByCreatedDateDesc(WorkType workType, Pageable pageable);
    Page<WorkLog> findByCreatedDateBetweenOrderByCreatedDateDesc(LocalDateTime startDate, LocalDateTime endDate, Pageable pageable);
    Page<WorkLog> findAllByOrderByCreatedDateDesc(Pageable pageable);
}
