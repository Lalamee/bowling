package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.WorkLogDTO;
import ru.bowling.bowlingapp.DTO.WorkLogSearchDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubEquipmentRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorkLogService {

    private final WorkLogRepository workLogRepository;
    private final WorkLogStatusHistoryRepository statusHistoryRepository;
    private final WorkLogPartUsageRepository partUsageRepository;
    private final MaintenanceRequestRepository maintenanceRequestRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final BowlingClubRepository clubRepository;
    private final ClubEquipmentRepository equipmentRepository;

    @Transactional
    public WorkLog createWorkLog(WorkLogDTO dto, Long userId) {
        WorkLog workLog = convertToEntity(dto);
        workLog.setCreatedBy(userId);
        workLog.setCreatedDate(LocalDateTime.now());
        return workLogRepository.save(workLog);
    }

    @Transactional(readOnly = true)
    public WorkLog getWorkLog(Long id) {
        return workLogRepository.findById(id).orElseThrow(() -> new RuntimeException("WorkLog not found with id: " + id));
    }

    @Transactional
    public WorkLog updateWorkLog(Long id, WorkLogDTO dto) {
        WorkLog existingWorkLog = getWorkLog(id);
        updateEntityFromDto(existingWorkLog, dto);
        return workLogRepository.save(existingWorkLog);
    }

    @Transactional
    public void deleteWorkLog(Long id) {
        if (!workLogRepository.existsById(id)) {
            throw new RuntimeException("WorkLog not found with id: " + id);
        }
        workLogRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Page<WorkLog> searchWorkLogs(WorkLogSearchDTO searchDTO, Long userId) {
        // TODO: Implement proper search logic using Specification or QueryDSL
        return workLogRepository.findAll(Pageable.unpaged());
    }

    private WorkLog convertToEntity(WorkLogDTO dto) {
        WorkLog workLog = new WorkLog();
        updateEntityFromDto(workLog, dto);
        return workLog;
    }

    private void updateEntityFromDto(WorkLog workLog, WorkLogDTO dto) {
        if (dto.getClubId() != null) {
            workLog.setClub(clubRepository.findById(dto.getClubId()).orElse(null));
        }
        if (dto.getEquipmentId() != null) {
            workLog.setEquipment(equipmentRepository.findById(dto.getEquipmentId()).orElse(null));
        }
        if (dto.getMechanicId() != null) {
            workLog.setMechanic(mechanicProfileRepository.findById(dto.getMechanicId()).orElse(null));
        }
        if (dto.getStatus() != null) {
            workLog.setStatus(WorkLogStatus.valueOf(dto.getStatus()));
        }
        if (dto.getWorkType() != null) {
            workLog.setWorkType(WorkType.valueOf(dto.getWorkType()));
        }
        workLog.setProblemDescription(dto.getProblemDescription());
        workLog.setWorkPerformed(dto.getWorkPerformed());
        workLog.setSolutionDescription(dto.getSolutionDescription());
        workLog.setActualHours(dto.getActualHours());
        workLog.setTotalCost(dto.getTotalCost());
        workLog.setPriority(dto.getPriority());
        workLog.setIsManualEdit(dto.getIsManualEdit());
    }

    @Transactional
    public WorkLog createWorkLogFromMaintenanceRequest(Long requestId, Long createdByUserId) {
        MaintenanceRequest request = maintenanceRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Maintenance request not found"));

        WorkLog workLog = WorkLog.builder()
                .maintenanceRequest(request)
                .club(request.getClub())
                .laneNumber(request.getLaneNumber())
                .mechanic(request.getMechanic())
                .createdDate(LocalDateTime.now())
                .status(WorkLogStatus.CREATED)
                .workType(WorkType.CORRECTIVE_MAINTENANCE)
                .problemDescription("Заявка на обслуживание: " + request.getManagerNotes())
                .priority(3) // Средний приоритет по умолчанию
                .createdBy(createdByUserId)
                .isManualEdit(false)
                .build();

        WorkLog savedWorkLog = workLogRepository.save(workLog);
        createStatusHistory(savedWorkLog, null, WorkLogStatus.CREATED, createdByUserId, "Создание записи на основе заявки");

        notificationService.notifyWorkLogCreated(savedWorkLog);

        log.info("Created work log {} for maintenance request {}", savedWorkLog.getLogId(), requestId);
        return savedWorkLog;
    }

    @Transactional
    public WorkLog createManualWorkLog(WorkLog workLog, Long createdByUserId) {
        workLog.setCreatedDate(LocalDateTime.now());
        workLog.setCreatedBy(createdByUserId);
        workLog.setStatus(WorkLogStatus.CREATED);
        workLog.setIsManualEdit(false);

        WorkLog savedWorkLog = workLogRepository.save(workLog);

        createStatusHistory(savedWorkLog, null, WorkLogStatus.CREATED, createdByUserId, "Ручное создание записи");

        notificationService.notifyWorkLogCreated(savedWorkLog);

        log.info("Created manual work log {} by user {}", savedWorkLog.getLogId(), createdByUserId);
        return savedWorkLog;
    }

    @Transactional
    public WorkLog updateWorkLogStatus(Long workLogId, WorkLogStatus newStatus, String reason, Long modifiedByUserId) {
        WorkLog workLog = workLogRepository.findById(workLogId)
                .orElseThrow(() -> new IllegalArgumentException("Work log not found"));

        WorkLogStatus previousStatus = workLog.getStatus();
        workLog.setStatus(newStatus);
        workLog.setModifiedBy(modifiedByUserId);
        workLog.setModifiedDate(LocalDateTime.now());

        switch (newStatus) {
            case IN_PROGRESS:
                if (workLog.getStartedDate() == null) {
                    workLog.setStartedDate(LocalDateTime.now());
                }
                break;
            case COMPLETED:
                workLog.setCompletedDate(LocalDateTime.now());
                break;
            case VERIFIED:
                break;
            case CLOSED:
                if (workLog.getCompletedDate() == null) {
                    workLog.setCompletedDate(LocalDateTime.now());
                }
                break;
        }

        WorkLog updatedWorkLog = workLogRepository.save(workLog);

        createStatusHistory(updatedWorkLog, previousStatus, newStatus, modifiedByUserId, reason);

        notificationService.notifyWorkLogStatusChanged(updatedWorkLog, previousStatus, newStatus);

        log.info("Updated work log {} status from {} to {} by user {}",
                workLogId, previousStatus, newStatus, modifiedByUserId);
        return updatedWorkLog;
    }

    @Transactional
    public WorkLog assignMechanic(Long workLogId, Long mechanicId, Long assignedByUserId) {
        WorkLog workLog = workLogRepository.findById(workLogId)
                .orElseThrow(() -> new IllegalArgumentException("Work log not found"));

        MechanicProfile mechanic = mechanicProfileRepository.findById(mechanicId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic not found"));

        workLog.setMechanic(mechanic);
        workLog.setStatus(WorkLogStatus.ASSIGNED);
        workLog.setModifiedBy(assignedByUserId);
        workLog.setModifiedDate(LocalDateTime.now());

        WorkLog updatedWorkLog = workLogRepository.save(workLog);

        createStatusHistory(updatedWorkLog, WorkLogStatus.CREATED, WorkLogStatus.ASSIGNED,
                assignedByUserId, "Назначен механик: " + mechanic.getFullName());

        notificationService.notifyWorkLogAssigned(updatedWorkLog, mechanic);

        log.info("Assigned mechanic {} to work log {} by user {}", mechanicId, workLogId, assignedByUserId);
        return updatedWorkLog;
    }

    @Transactional
    public WorkLog updateWorkDetails(Long workLogId, String workPerformed, String solutionDescription,
                                   Double actualHours, Integer qualityRating, Long modifiedByUserId) {
        WorkLog workLog = workLogRepository.findById(workLogId)
                .orElseThrow(() -> new IllegalArgumentException("Work log not found"));

        workLog.setWorkPerformed(workPerformed);
        workLog.setSolutionDescription(solutionDescription);
        workLog.setActualHours(actualHours);
        workLog.setQualityRating(qualityRating);
        workLog.setModifiedBy(modifiedByUserId);
        workLog.setModifiedDate(LocalDateTime.now());

        calculateTotalCost(workLog);

        WorkLog updatedWorkLog = workLogRepository.save(workLog);

        log.info("Updated work details for log {} by user {}", workLogId, modifiedByUserId);
        return updatedWorkLog;
    }

    @Transactional
    public WorkLog manualEdit(Long workLogId, WorkLog updatedData, String editReason, Long editedByUserId) {
        WorkLog existingWorkLog = workLogRepository.findById(workLogId)
                .orElseThrow(() -> new IllegalArgumentException("Work log not found"));

        updatedData.setLogId(existingWorkLog.getLogId());
        updatedData.setCreatedDate(existingWorkLog.getCreatedDate());
        updatedData.setCreatedBy(existingWorkLog.getCreatedBy());
        updatedData.setVersion(existingWorkLog.getVersion());

        updatedData.setIsManualEdit(true);
        updatedData.setManualEditReason(editReason);
        updatedData.setModifiedBy(editedByUserId);
        updatedData.setModifiedDate(LocalDateTime.now());

        calculateTotalCost(updatedData);

        WorkLog savedWorkLog = workLogRepository.save(updatedData);

        createStatusHistory(savedWorkLog, existingWorkLog.getStatus(), savedWorkLog.getStatus(),
                editedByUserId, "Ручное редактирование: " + editReason);

        log.info("Manual edit of work log {} by user {}: {}", workLogId, editedByUserId, editReason);
        return savedWorkLog;
    }

    @Transactional(readOnly = true)
    public List<WorkLog> findWorkLogsByFilters(Long clubId, Integer laneNumber, Long mechanicId,
                                             WorkLogStatus status, WorkType workType,
                                             LocalDateTime startDate, LocalDateTime endDate, Long equipmentId) {

        if (clubId != null && laneNumber != null) {
            return workLogRepository.findByClubClubIdAndLaneNumberOrderByCreatedDateDesc(clubId, laneNumber);
        }

        if (clubId != null && status != null) {
            return workLogRepository.findByClubClubIdAndStatusOrderByCreatedDateDesc(clubId, status);
        }

        if (mechanicId != null && status != null) {
            return workLogRepository.findByMechanicProfileIdAndStatusOrderByCreatedDateDesc(mechanicId, status);
        }

        if (workType != null && status != null) {
            return workLogRepository.findByWorkTypeAndStatusOrderByCreatedDateDesc(workType, status);
        }

        if (equipmentId != null) {
            return workLogRepository.findByEquipmentEquipmentIdOrderByCreatedDateDesc(equipmentId);
        }

        if (mechanicId != null) {
            return workLogRepository.findByMechanicProfileIdOrderByCreatedDateDesc(mechanicId);
        }

        if (clubId != null) {
            return workLogRepository.findByClubClubIdOrderByCreatedDateDesc(clubId);
        }

        if (status != null) {
            return workLogRepository.findByStatusOrderByCreatedDateDesc(status);
        }

        if (workType != null) {
            return workLogRepository.findByWorkTypeOrderByCreatedDateDesc(workType);
        }

        if (startDate != null && endDate != null) {
            return workLogRepository.findByCreatedDateBetweenOrderByCreatedDateDesc(startDate, endDate);
        }

        return workLogRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<WorkLog> getActiveWorkLogs() {
        List<WorkLogStatus> activeStatuses = List.of(
                WorkLogStatus.CREATED,
                WorkLogStatus.ASSIGNED,
                WorkLogStatus.IN_PROGRESS
        );
        return workLogRepository.findByStatusInOrderByCreatedDateDesc(activeStatuses);
    }

    @Transactional(readOnly = true)
    public List<WorkLog> getHighPriorityWorkLogs() {
        return workLogRepository.findByPriorityLessThanEqualOrderByPriorityAscCreatedDateDesc(2);
    }

    @Transactional(readOnly = true)
    public List<WorkLog> getWorkLogsByMechanic(Long mechanicId) {
        return workLogRepository.findByMechanicProfileIdOrderByCreatedDateDesc(mechanicId);
    }

    @Transactional(readOnly = true)
    public Page<WorkLog> getWorkLogsPageable(Pageable pageable) {
        return workLogRepository.findAllByOrderByCreatedDateDesc(pageable);
    }

    @Transactional(readOnly = true)
    public Optional<WorkLog> getWorkLogById(Long workLogId) {
        return workLogRepository.findById(workLogId);
    }

    @Transactional(readOnly = true)
    public List<WorkLog> getCompletedWorkLogs() {
        return workLogRepository.findByCompletedDateIsNotNullOrderByCompletedDateDesc();
    }

    @Transactional(readOnly = true)
    public List<WorkLog> getPendingWorkLogs() {
        return workLogRepository.findByCompletedDateIsNullOrderByCreatedDateDesc();
    }

    private void createStatusHistory(WorkLog workLog, WorkLogStatus previousStatus,
                                   WorkLogStatus newStatus, Long changedByUserId, String reason) {
        User changedBy = userRepository.findById(changedByUserId).orElse(null);

        WorkLogStatusHistory statusHistory = WorkLogStatusHistory.builder()
                .workLog(workLog)
                .previousStatus(previousStatus)
                .newStatus(newStatus)
                .changedDate(LocalDateTime.now())
                .changedBy(changedBy)
                .reason(reason)
                .build();

        statusHistoryRepository.save(statusHistory);
    }

    private void calculateTotalCost(WorkLog workLog) {
        Double laborCost = workLog.getLaborCost() != null ? workLog.getLaborCost() : 0.0;
        Double partsCost = workLog.getTotalPartsCost() != null ? workLog.getTotalPartsCost() : 0.0;
        workLog.setTotalCost(laborCost + partsCost);
    }
}
