package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OwnerDashboardService {

    private final ClubEquipmentRepository clubEquipmentRepository;
    private final EquipmentComponentRepository equipmentComponentRepository;
    private final EquipmentMaintenanceScheduleRepository equipmentMaintenanceScheduleRepository;
    private final WorkLogRepository workLogRepository;
    private final WorkLogPartUsageRepository workLogPartUsageRepository;
    private final ServiceHistoryPartRepository serviceHistoryPartRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final NotificationService notificationService;

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
                        .productionYear(eq.getProductionYear())
                        .lanesCount(eq.getLanesCount())
                        .conditionPercentage(eq.getConditionPercentage())
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

        return logs.stream()
                .filter(log -> laneNumber == null || Objects.equals(log.getLaneNumber(), laneNumber))
                .filter(log -> workType == null || workType.equals(log.getWorkType()))
                .filter(log -> status == null || status.equals(log.getStatus()))
                .filter(log -> start == null || (log.getCreatedDate() != null && !log.getCreatedDate().isBefore(start)))
                .filter(log -> end == null || (log.getCreatedDate() != null && !log.getCreatedDate().isAfter(end)))
                .map(this::toJournalEntry)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<WarningDTO> getWarnings(Long userId, Long clubId) {
        Long resolvedClubId = resolveClubForUser(userId, clubId);
        LocalDate today = LocalDate.now();

        List<WarningDTO> scheduleWarnings = equipmentMaintenanceScheduleRepository.findByClubClubId(resolvedClubId).stream()
                .flatMap(schedule -> {
                    if (schedule.getScheduledDate() == null) {
                        return List.<WarningDTO>of().stream();
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
                    return List.of(overdue, upcoming).stream().filter(Objects::nonNull);
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

        return List.of(scheduleWarnings, equipmentWarnings, partWarnings).stream()
                .flatMap(List::stream)
                .sorted(Comparator.comparing(WarningDTO::getDueDate, Comparator.nullsLast(LocalDate::compareTo)))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<NotificationEvent> getManagerNotifications(Long userId, Long clubId, RoleName roleName) {
        Long resolvedClubId = resolveClubForUser(userId, clubId);
        return notificationService.getNotificationsForRole(roleName == null ? RoleName.CLUB_OWNER : roleName).stream()
                .filter(event -> event.getClubId() == null || Objects.equals(event.getClubId(), resolvedClubId))
                .collect(Collectors.toList());
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

        return ServiceJournalEntryDTO.builder()
                .workLogId(log.getLogId())
                .requestId(log.getMaintenanceRequest() != null ? log.getMaintenanceRequest().getRequestId() : null)
                .laneNumber(log.getLaneNumber())
                .equipmentId(log.getEquipment() != null ? log.getEquipment().getEquipmentId() : null)
                .equipmentModel(log.getEquipment() != null ? log.getEquipment().getModel() : null)
                .workType(log.getWorkType())
                .status(log.getStatus())
                .createdDate(log.getCreatedDate())
                .completedDate(log.getCompletedDate())
                .mechanicName(log.getMechanic() != null ? log.getMechanic().getFullName() : null)
                .partsUsed(parts)
                .build();
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
        if (explicitClubId != null) {
            boolean allowed = clubStaffRepository.existsByClubClubIdAndUserUserIdAndIsActiveTrue(explicitClubId, userId);
            if (!allowed) {
                throw new IllegalArgumentException("Пользователь не привязан к клубу");
            }
            return explicitClubId;
        }
        return clubStaffRepository.findByUserUserIdAndIsActiveTrue(userId).stream()
                .findFirst()
                .map(staff -> staff.getClub().getClubId())
                .orElseThrow(() -> new IllegalArgumentException("Для пользователя не найден активный клуб"));
    }

    private String readableEquipment(EquipmentMaintenanceSchedule schedule) {
        ClubEquipment eq = schedule.getEquipment();
        if (eq == null) {
            return "оборудования";
        }
        return Optional.ofNullable(eq.getModel()).orElse("оборудование") + " (ID " + eq.getEquipmentId() + ")";
    }
}
