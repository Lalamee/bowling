package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Entity.ServiceHistory;
import ru.bowling.bowlingapp.Entity.WorkLogStatusHistory;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class OwnerDashboardService {

    private final ClubEquipmentRepository clubEquipmentRepository;
    private final EquipmentComponentRepository equipmentComponentRepository;
    private final EquipmentMaintenanceScheduleRepository equipmentMaintenanceScheduleRepository;
    private final WorkLogRepository workLogRepository;
    private final WorkLogPartUsageRepository workLogPartUsageRepository;
    private final ServiceHistoryPartRepository serviceHistoryPartRepository;
    private final ServiceHistoryRepository serviceHistoryRepository;
    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final UserClubAccessService userClubAccessService;

    @Transactional
    public NotificationEvent submitClubAppeal(Long userId, ClubAppealRequestDTO request) {
        if (request == null || request.getType() == null || request.getMessage() == null || request.getMessage().isBlank()) {
            throw new IllegalArgumentException("Appeal data is required");
        }

        if (!isClubAppealType(request.getType())) {
            throw new IllegalArgumentException("Unsupported appeal type");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        Long resolvedClubId = resolveClubForUser(user, request.getClubId());

        return notificationService.notifyClubAppeal(
                user,
                resolvedClubId,
                request.getType(),
                request.getMessage(),
                request.getRequestId()
        );
    }

    @Transactional(readOnly = true)
    public List<TechnicalInfoDTO> getTechnicalInformation(Long userId, Long clubId) {
        Long resolvedClubId = resolveClubForUser(userId, clubId);
        List<EquipmentComponentDTO> components = equipmentComponentRepository.findAll().stream()
                .map(this::toComponentDto)
                .toList();

        return clubEquipmentRepository.findByClubClubId(resolvedClubId).stream()
                .map(eq -> TechnicalInfoDTO.builder()
                        .equipmentId(eq.getEquipmentId())
                        .model(eq.getModel())
                        .serialNumber(eq.getSerialNumber())
                        .equipmentType(eq.getEquipmentType() != null ? eq.getEquipmentType().getName() : null)
                        .manufacturer(eq.getManufacturer() != null ? eq.getManufacturer().getName() : eq.getOtherManufacturerName())
                        .productionYear(eq.getProductionYear())
                        .lanesCount(eq.getLanesCount())
                        .conditionPercentage(eq.getConditionPercentage())
                        .purchaseDate(eq.getPurchaseDate())
                        .warrantyUntil(eq.getWarrantyUntil())
                        .status(eq.getStatus())
                        .lastMaintenanceDate(eq.getLastMaintenanceDate())
                        .nextMaintenanceDate(eq.getNextMaintenanceDate())
                        .components(components)
                        .schedules(equipmentMaintenanceScheduleRepository.findByEquipmentEquipmentId(eq.getEquipmentId()).stream()
                                .map(this::toScheduleDto)
                                .toList())
                        .build())
                .sorted(Comparator.comparing(TechnicalInfoDTO::getEquipmentId))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ServiceJournalEntryDTO> getServiceJournal(Long userId,
                                                          Long clubId,
                                                          Integer laneNumber,
                                                          LocalDateTime start,
                                                          LocalDateTime end,
                                                          WorkType workType,
                                                          WorkLogStatus status) {
        Long resolvedClubId = resolveClubForUser(userId, clubId);
        List<WorkLog> logs = workLogRepository.findByClubClubIdOrderByCreatedDateDesc(resolvedClubId);

        List<ServiceJournalEntryDTO> workLogEntries = logs.stream()
                .filter(log -> laneNumber == null || Objects.equals(log.getLaneNumber(), laneNumber))
                .filter(log -> workType == null || workType.equals(log.getWorkType()))
                .filter(log -> status == null || status.equals(log.getStatus()))
                .filter(log -> start == null || (log.getCreatedDate() != null && !log.getCreatedDate().isBefore(start)))
                .filter(log -> end == null || (log.getCreatedDate() != null && !log.getCreatedDate().isAfter(end)))
                .map(this::toJournalEntry)
                .collect(Collectors.toList());

        List<ServiceJournalEntryDTO> serviceHistoryEntries = serviceHistoryRepository.findByClubClubIdOrderByServiceDateDesc(resolvedClubId)
                .stream()
                .filter(history -> laneNumber == null || Objects.equals(history.getLaneNumber(), laneNumber))
                .filter(history -> start == null || (history.getServiceDate() != null && !history.getServiceDate().isBefore(start)))
                .filter(history -> end == null || (history.getServiceDate() != null && !history.getServiceDate().isAfter(end)))
                .map(this::toJournalEntry)
                .collect(Collectors.toList());

        Stream<ServiceJournalEntryDTO> combined = Stream.concat(workLogEntries.stream(), serviceHistoryEntries.stream());

        return combined
                .sorted(Comparator.comparing((ServiceJournalEntryDTO entry) ->
                                Optional.ofNullable(entry.getCompletedDate()).orElse(entry.getServiceDate()),
                        Comparator.nullsLast(LocalDateTime::compareTo))
                        .reversed())
                .toList();
    }

    @Transactional(readOnly = true)
    public List<WarningDTO> getWarnings(Long userId, Long clubId) {
        Long resolvedClubId = resolveClubForUser(userId, clubId);
        LocalDate today = LocalDate.now();

        List<WarningDTO> scheduleWarnings = equipmentMaintenanceScheduleRepository.findByClubClubId(resolvedClubId).stream()
                .flatMap(schedule -> {
                    WarningDTO criticalMissing = null;
                    if (Boolean.TRUE.equals(schedule.getIsCritical()) && schedule.getLastPerformed() == null) {
                        criticalMissing = WarningDTO.builder()
                                .type("CRITICAL_MAINTENANCE_MISSING")
                                .message("Критичное оборудование без запланированного ТО: " + readableEquipment(schedule))
                                .equipmentId(schedule.getEquipment() != null ? schedule.getEquipment().getEquipmentId() : null)
                                .scheduleId(schedule.getScheduleId())
                                .dueDate(schedule.getScheduledDate())
                                .build();
                    }
                    if (schedule.getScheduledDate() == null) {
                        return List.of(criticalMissing).stream().filter(Objects::nonNull);
                    }
                    WarningDTO overdue = null;
                    WarningDTO upcoming = null;
                    if (schedule.getScheduledDate().isBefore(today) && (schedule.getLastPerformed() == null || schedule.getLastPerformed().isBefore(schedule.getScheduledDate()))) {
                        overdue = WarningDTO.builder()
                                .type("MAINTENANCE_OVERDUE")
                                .message("Просроченное ТО для " + readableEquipment(schedule))
                                .equipmentId(schedule.getEquipment() != null ? schedule.getEquipment().getEquipmentId() : null)
                                .scheduleId(schedule.getScheduleId())
                                .dueDate(schedule.getScheduledDate())
                                .build();
                    } else if (!schedule.getScheduledDate().isAfter(today.plusDays(14))) {
                        upcoming = WarningDTO.builder()
                                .type("MAINTENANCE_DUE_SOON")
                                .message("Скоро плановое ТО для " + readableEquipment(schedule))
                                .equipmentId(schedule.getEquipment() != null ? schedule.getEquipment().getEquipmentId() : null)
                                .scheduleId(schedule.getScheduleId())
                                .dueDate(schedule.getScheduledDate())
                                .build();
                    }
                    return Stream.of(overdue, upcoming, criticalMissing).filter(Objects::nonNull);
                })
                .toList();

        List<WarningDTO> equipmentWarnings = clubEquipmentRepository.findByClubClubId(resolvedClubId).stream()
                .filter(eq -> eq.getNextMaintenanceDate() != null && eq.getNextMaintenanceDate().isBefore(today))
                .map(eq -> WarningDTO.builder()
                        .type("EQUIPMENT_NEXT_MAINTENANCE_OVERDUE")
                        .message("Истек плановый срок обслуживания оборудования " + Optional.ofNullable(eq.getModel()).orElse("оборудование"))
                        .equipmentId(eq.getEquipmentId())
                        .dueDate(eq.getNextMaintenanceDate())
                        .build())
                .toList();

        List<WarningDTO> partWarnings = serviceHistoryPartRepository.findByServiceHistoryClubClubId(resolvedClubId).stream()
                .filter(part -> part.getPartsCatalog() != null && part.getPartsCatalog().getNormalServiceLife() != null)
                .filter(part -> part.getCreatedDate() != null)
                .filter(part -> part.getCreatedDate().toLocalDate().plusMonths(part.getPartsCatalog().getNormalServiceLife()).isBefore(today))
                .map(part -> WarningDTO.builder()
                        .type("PART_SERVICE_LIFE_EXCEEDED")
                        .message("Превышен ресурс детали " + Optional.ofNullable(part.getPartName()).orElse(part.getCatalogNumber()))
                        .partCatalogId(part.getPartsCatalog().getCatalogId())
                        .dueDate(part.getCreatedDate().toLocalDate().plusMonths(part.getPartsCatalog().getNormalServiceLife()))
                        .build())
                .toList();

        return Stream.of(scheduleWarnings, equipmentWarnings, partWarnings)
                .flatMap(List::stream)
                .sorted(Comparator.comparing(WarningDTO::getDueDate, Comparator.nullsLast(LocalDate::compareTo)))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<NotificationEvent> getManagerNotifications(Long userId, Long clubId, RoleName roleName) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        List<Long> accessibleClubIds = userClubAccessService.resolveAccessibleClubIds(user);
        Long resolvedClubId = resolveClubForNotifications(clubId, accessibleClubIds);
        List<NotificationEvent> filtered = notificationService.getNotificationsForUser(user, accessibleClubIds).stream()
                .filter(event -> resolvedClubId == null || event.getClubId() == null || Objects.equals(event.getClubId(), resolvedClubId))
                .toList();
        List<NotificationEvent> events = new ArrayList<>(filtered);

        if (resolvedClubId != null) {
            getWarnings(userId, resolvedClubId).forEach(warning -> events.add(NotificationEvent.builder()
                    .id(UUID.randomUUID())
                    .type(NotificationEventType.MAINTENANCE_WARNING)
                    .message(warning.getMessage())
                    .clubId(resolvedClubId)
                    .createdAt(LocalDateTime.now())
                    .payload(warning.getType())
                    .audiences(Set.of(RoleName.ADMIN, RoleName.CLUB_OWNER, RoleName.HEAD_MECHANIC))
                    .build()));
        }

        return events;
    }

    private ServiceJournalEntryDTO toJournalEntry(WorkLog log) {
        List<WorkLogPartUsageDTO> parts = workLogPartUsageRepository.findByWorkLogLogIdOrderByInstalledDate(log.getLogId()).stream()
                .map(part -> WorkLogPartUsageDTO.builder()
                        .usageId(part.getUsageId())
                        .partName(part.getPartName())
                        .catalogNumber(part.getCatalogNumber())
                        .quantityUsed(part.getQuantityUsed())
                        .totalCost(part.getTotalCost())
                .build())
                .toList();

        LocalDateTime finished = resolveCompletionDate(log);

        return ServiceJournalEntryDTO.builder()
                .workLogId(log.getLogId())
                .requestId(log.getMaintenanceRequest() != null ? log.getMaintenanceRequest().getRequestId() : null)
                .serviceHistoryId(null)
                .laneNumber(log.getLaneNumber())
                .equipmentId(log.getEquipment() != null ? log.getEquipment().getEquipmentId() : null)
                .equipmentModel(log.getEquipment() != null ? log.getEquipment().getModel() : null)
                .workType(log.getWorkType())
                .serviceType(null)
                .status(log.getStatus())
                .requestStatus(log.getMaintenanceRequest() != null ? log.getMaintenanceRequest().getStatus() : null)
                .createdDate(log.getCreatedDate())
                .completedDate(finished)
                .serviceDate(finished != null ? finished : log.getCreatedDate())
                .mechanicName(log.getMechanic() != null ? log.getMechanic().getFullName() : null)
                .partsUsed(parts)
                .build();
    }

    private ServiceJournalEntryDTO toJournalEntry(ServiceHistory history) {
        List<WorkLogPartUsageDTO> parts = serviceHistoryPartRepository.findByServiceHistoryServiceIdOrderByCreatedDate(history.getServiceId())
                .stream()
                .map(part -> WorkLogPartUsageDTO.builder()
                        .usageId(part.getId())
                        .partName(part.getPartName())
                        .catalogNumber(part.getCatalogNumber())
                        .quantityUsed(part.getQuantity())
                        .totalCost(part.getTotalCost())
                        .build())
                .toList();

        return ServiceJournalEntryDTO.builder()
                .workLogId(null)
                .requestId(null)
                .serviceHistoryId(history.getServiceId())
                .laneNumber(history.getLaneNumber())
                .equipmentId(history.getEquipment() != null ? history.getEquipment().getEquipmentId() : null)
                .equipmentModel(history.getEquipment() != null ? history.getEquipment().getModel() : null)
                .workType(null)
                .serviceType(history.getServiceType())
                .status(null)
                .requestStatus(null)
                .createdDate(history.getCreatedDate())
                .completedDate(history.getServiceDate())
                .serviceDate(history.getServiceDate())
                .mechanicName(history.getPerformedBy() != null ? history.getPerformedBy().getFullName() : null)
                .partsUsed(parts)
                .build();
    }

    private LocalDateTime resolveCompletionDate(WorkLog log) {
        if (log.getCompletedDate() != null) {
            return log.getCompletedDate();
        }
        if (log.getStatusHistory() == null) {
            return null;
        }
        return log.getStatusHistory().stream()
                .filter(h -> h.getNewStatus() == WorkLogStatus.COMPLETED || h.getNewStatus() == WorkLogStatus.VERIFIED || h.getNewStatus() == WorkLogStatus.CLOSED)
                .map(WorkLogStatusHistory::getChangedDate)
                .filter(Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    private EquipmentComponentDTO toComponentDto(EquipmentComponent component) {
        return EquipmentComponentDTO.builder()
                .componentId(component.getComponentId())
                .name(component.getName())
                .manufacturer(component.getManufacturer())
                .category(component.getCategory())
                .code(component.getCode())
                .notes(component.getNotes())
                .parentId(component.getParent() != null ? component.getParent().getComponentId() : null)
                .build();
    }

    private MaintenanceScheduleDTO toScheduleDto(EquipmentMaintenanceSchedule schedule) {
        return MaintenanceScheduleDTO.builder()
                .scheduleId(schedule.getScheduleId())
                .maintenanceType(schedule.getMaintenanceType())
                .scheduledDate(schedule.getScheduledDate())
                .lastPerformed(schedule.getLastPerformed())
                .critical(schedule.getIsCritical())
                .build();
    }

    private Long resolveClubForUser(Long userId, Long explicitClubId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        return resolveClubForUser(user, explicitClubId);
    }

    private Long resolveClubForUser(User user, Long explicitClubId) {
        List<Long> accessibleClubIds = userClubAccessService.resolveAccessibleClubIds(user);
        if (explicitClubId != null) {
            boolean allowed = accessibleClubIds.contains(explicitClubId);
            if (!allowed) {
                throw new IllegalArgumentException("Пользователь не привязан к клубу");
            }
            return explicitClubId;
        }
        return accessibleClubIds.stream()
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Для пользователя не найден активный клуб"));
    }

    private Long resolveClubForNotifications(Long explicitClubId, List<Long> accessibleClubIds) {
        if (explicitClubId != null) {
            if (!accessibleClubIds.contains(explicitClubId)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Нет доступа к выбранному клубу");
            }
            return explicitClubId;
        }
        return accessibleClubIds.stream().findFirst().orElse(null);
    }

    private boolean isClubAppealType(NotificationEventType type) {
        return type == NotificationEventType.CLUB_TECH_SUPPORT
                || type == NotificationEventType.CLUB_SUPPLIER_REFUSAL
                || type == NotificationEventType.CLUB_MECHANIC_FAILURE
                || type == NotificationEventType.CLUB_LEGAL_ASSISTANCE
                || type == NotificationEventType.CLUB_SPECIALIST_ACCESS;
    }

    private String readableEquipment(EquipmentMaintenanceSchedule schedule) {
        ClubEquipment eq = schedule.getEquipment();
        if (eq == null) {
            return "оборудования";
        }
        return Optional.ofNullable(eq.getModel()).orElse("оборудование") + " (ID " + eq.getEquipmentId() + ")";
    }
}
