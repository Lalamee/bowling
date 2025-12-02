package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.DTO.ServiceJournalEntryDTO;
import ru.bowling.bowlingapp.DTO.TechnicalInfoDTO;
import ru.bowling.bowlingapp.DTO.WarningDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.NotificationService;
import ru.bowling.bowlingapp.Service.OwnerDashboardService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class OwnerDashboardIntegrationTest {

    @Autowired
    private OwnerDashboardService ownerDashboardService;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private ClubEquipmentRepository clubEquipmentRepository;

    @Autowired
    private EquipmentMaintenanceScheduleRepository scheduleRepository;

    @Autowired
    private WorkLogRepository workLogRepository;

    @Autowired
    private WorkLogPartUsageRepository workLogPartUsageRepository;

    @Autowired
    private ServiceHistoryPartRepository serviceHistoryPartRepository;

    @Autowired
    private ServiceHistoryRepository serviceHistoryRepository;

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private NotificationService notificationService;

    @Test
    void ownerSeesTechnicalInfoWarningsHistoryAndNotificationsForOwnClub() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Manager Club")
                .createdAt(LocalDate.now())
                .build());

        Role ownerRole = roleRepository.save(Role.builder().name("CLUB_OWNER").build());
        AccountType accountType = accountTypeRepository.save(AccountType.builder().name("CLUB_OWNER").build());

        User owner = userRepository.save(User.builder()
                .phone("+79998887766")
                .passwordHash("pwd")
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .role(ownerRole)
                .accountType(accountType)
                .build());

        clubStaffRepository.save(ClubStaff.builder()
                .club(club)
                .user(owner)
                .isActive(true)
                .build());

        ClubEquipment equipment = clubEquipmentRepository.save(ClubEquipment.builder()
                .club(club)
                .model("Pinsetter X1")
                .productionYear(2018)
                .lanesCount(2)
                .conditionPercentage(75)
                .lastMaintenanceDate(LocalDate.now().minusMonths(6))
                .nextMaintenanceDate(LocalDate.now().minusDays(2))
                .build());

        scheduleRepository.save(EquipmentMaintenanceSchedule.builder()
                .club(club)
                .equipment(equipment)
                .maintenanceType("Quarterly")
                .scheduledDate(LocalDate.now().minusDays(5))
                .lastPerformed(LocalDate.now().minusMonths(4))
                .isCritical(true)
                .build());

        WorkLog workLog = workLogRepository.save(WorkLog.builder()
                .club(club)
                .equipment(equipment)
                .laneNumber(1)
                .createdDate(LocalDateTime.now().minusDays(10))
                .completedDate(LocalDateTime.now().minusDays(9))
                .workType(WorkType.CORRECTIVE_MAINTENANCE)
                .status(WorkLogStatus.COMPLETED)
                .build());

        PartsCatalog catalog = partsCatalogRepository.save(PartsCatalog.builder()
                .catalogNumber("CAT-777")
                .officialNameRu("Ролик")
                .commonName("Ролик")
                .normalServiceLife(6)
                .build());

        workLogPartUsageRepository.save(WorkLogPartUsage.builder()
                .workLog(workLog)
                .partsCatalog(catalog)
                .partName("Ролик подачи")
                .catalogNumber("CAT-777")
                .quantityUsed(1)
                .totalCost(1500.0)
                .createdDate(LocalDateTime.now().minusDays(10))
                .build());

        ServiceHistory serviceHistory = serviceHistoryRepository.save(ServiceHistory.builder()
                .club(club)
                .equipment(equipment)
                .createdDate(LocalDateTime.now().minusMonths(7))
                .build());

        serviceHistoryPartRepository.save(ServiceHistoryPart.builder()
                .serviceHistory(serviceHistory)
                .partsCatalog(catalog)
                .partName("Ролик подачи")
                .catalogNumber("CAT-777")
                .createdDate(LocalDateTime.now().minusMonths(7))
                .build());

        serviceHistoryPartRepository.save(ServiceHistoryPart.builder()
                .partsCatalog(catalog)
                .partName("Ролик подачи")
                .catalogNumber("CAT-777")
                .createdDate(LocalDateTime.now().minusMonths(7))
                .build());

        notificationService.notifyHelpRequested(null, List.of(), "Нужна помощь");

        List<TechnicalInfoDTO> techInfo = ownerDashboardService.getTechnicalInformation(owner.getUserId(), club.getClubId());
        assertThat(techInfo).hasSize(1);
        assertThat(techInfo.get(0).getSchedules()).isNotEmpty();

        List<ServiceJournalEntryDTO> journal = ownerDashboardService.getServiceJournal(owner.getUserId(), club.getClubId(), null, null, null, null, null);
        assertThat(journal).hasSize(1);
        assertThat(journal.get(0).getPartsUsed()).isNotEmpty();

        List<WarningDTO> warnings = ownerDashboardService.getWarnings(owner.getUserId(), club.getClubId());
        assertThat(warnings).anyMatch(w -> "MAINTENANCE_OVERDUE".equals(w.getType()));
        assertThat(warnings).anyMatch(w -> "PART_SERVICE_LIFE_EXCEEDED".equals(w.getType()));

        List<NotificationEvent> notifications = ownerDashboardService.getManagerNotifications(owner.getUserId(), club.getClubId(), RoleName.CLUB_OWNER);
        assertThat(notifications).anyMatch(e -> e.getType() != null);
    }
}
