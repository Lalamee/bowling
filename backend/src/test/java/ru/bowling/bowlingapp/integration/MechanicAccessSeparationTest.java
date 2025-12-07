package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.MechanicProfileDTO;
import ru.bowling.bowlingapp.DTO.RegisterUserDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.WorkLogStatus;
import ru.bowling.bowlingapp.Entity.enums.WorkType;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.AuthService;
import ru.bowling.bowlingapp.Service.InvitationService;
import ru.bowling.bowlingapp.Service.WorkLogService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class MechanicAccessSeparationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private InvitationService invitationService;

    @Autowired
    private WorkLogService workLogService;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private WorkLogRepository workLogRepository;

    @Autowired
    private ClubInvitationRepository clubInvitationRepository;

    @BeforeEach
    void ensureDictionaries() {
        for (RoleName roleName : RoleName.values()) {
            roleRepository.findByNameIgnoreCase(roleName.name())
                    .orElseGet(() -> roleRepository.save(Role.builder().name(roleName.name()).build()));
        }
        for (AccountTypeName typeName : AccountTypeName.values()) {
            accountTypeRepository.findByNameIgnoreCase(typeName.name())
                    .orElseGet(() -> accountTypeRepository.save(AccountType.builder().name(typeName.name()).build()));
        }
    }

    @Test
    void freeEntrepreneurRemainsDetachedFromClubs() {
        AccountType freePremium = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_PREMIUM.name()).orElseThrow();
        Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow();

        RegisterUserDTO register = RegisterUserDTO.builder()
                .phone("+79995553322")
                .password("IpMechanic123")
                .roleId(mechanicRole.getRoleId().intValue())
                .accountTypeId(freePremium.getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO profileDto = MechanicProfileDTO.builder()
                .fullName("ИП Механик")
                .birthDate(LocalDate.of(1988, 3, 3))
                .totalExperienceYears(10)
                .bowlingExperienceYears(5)
                .isEntrepreneur(true)
                .region("Новосибирск")
                .skills("ремонт")
                .advantages("скорость")
                .build();

        authService.registerUser(register, profileDto, null, null, null);

        User saved = userRepository.findByPhone("+79995553322").orElseThrow();
        assertThat(saved.getAccountType().getName()).isEqualTo(AccountTypeName.FREE_MECHANIC_PREMIUM.name());
        assertThat(saved.getMechanicProfile().getIsEntrepreneur()).isTrue();
        assertThat(saved.getMechanicProfile().getClubs()).isEmpty();
        assertThat(clubStaffRepository.findByUserUserId(saved.getUserId())).isEmpty();
        assertThat(clubInvitationRepository.findByMechanic_UserIdAndStatus(saved.getUserId(), "ACCEPTED")).isEmpty();
    }

    @Test
    void laneAndMaintenanceVisibilityFollowMechanicTypeAndAccess() {
        BowlingClub clubA = bowlingClubRepository.save(BowlingClub.builder()
                .name("Club A")
                .address("Address A")
                .lanesCount(6)
                .isActive(true)
                .isVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        BowlingClub clubB = bowlingClubRepository.save(BowlingClub.builder()
                .name("Club B")
                .address("Address B")
                .lanesCount(8)
                .isActive(true)
                .isVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow();
        AccountType clubAccount = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name()).orElseThrow();
        AccountType freeAccount = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_BASIC.name()).orElseThrow();

        RegisterUserDTO clubMechanic = RegisterUserDTO.builder()
                .phone("+79997770001")
                .password("ClubMechanic123")
                .roleId(mechanicRole.getRoleId().intValue())
                .accountTypeId(clubAccount.getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO clubMechanicProfile = MechanicProfileDTO.builder()
                .fullName("Штатный механик")
                .birthDate(LocalDate.of(1991, 1, 1))
                .totalExperienceYears(5)
                .bowlingExperienceYears(3)
                .isEntrepreneur(false)
                .region("Москва")
                .clubId(clubA.getClubId())
                .build();

        authService.registerUser(clubMechanic, clubMechanicProfile, null, null, null);
        User clubMechanicUser = userRepository.findByPhone("+79997770001").orElseThrow();

        RegisterUserDTO freeMechanic = RegisterUserDTO.builder()
                .phone("+79997770002")
                .password("FreeMechanic123")
                .roleId(mechanicRole.getRoleId().intValue())
                .accountTypeId(freeAccount.getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO freeMechanicProfile = MechanicProfileDTO.builder()
                .fullName("Свободный механик")
                .birthDate(LocalDate.of(1993, 2, 2))
                .totalExperienceYears(4)
                .bowlingExperienceYears(2)
                .isEntrepreneur(true)
                .region("Казань")
                .build();

        authService.registerUser(freeMechanic, freeMechanicProfile, null, null, null);
        User freeMechanicUser = userRepository.findByPhone("+79997770002").orElseThrow();

        invitationService.inviteMechanic(clubB.getClubId(), freeMechanicUser.getUserId());
        ClubInvitation invitation = clubInvitationRepository.findByMechanic_UserIdAndStatus(freeMechanicUser.getUserId(), "PENDING").get(0);
        invitationService.acceptInvitation(invitation.getId());

        WorkLog clubLog = workLogRepository.save(WorkLog.builder()
                .club(clubA)
                .mechanic(clubMechanicUser.getMechanicProfile())
                .laneNumber(1)
                .createdDate(LocalDateTime.now())
                .status(WorkLogStatus.COMPLETED)
                .workType(WorkType.REPAIR)
                .build());

        WorkLog freeLog = workLogRepository.save(WorkLog.builder()
                .club(clubB)
                .mechanic(freeMechanicUser.getMechanicProfile())
                .laneNumber(2)
                .createdDate(LocalDateTime.now())
                .status(WorkLogStatus.IN_PROGRESS)
                .workType(WorkType.MAINTENANCE)
                .build());

        List<WorkLog> clubMechanicLogs = workLogService.searchWorkLogs(null, clubMechanicUser.getUserId()).getContent();
        assertThat(clubMechanicLogs)
                .extracting(WorkLog::getLogId)
                .containsExactly(clubLog.getLogId());

        assertThat(clubStaffRepository.findByUserUserIdAndIsActiveTrue(clubMechanicUser.getUserId())).isNotEmpty();

        List<WorkLog> freeMechanicLogs = workLogService.searchWorkLogs(null, freeMechanicUser.getUserId()).getContent();
        assertThat(freeMechanicLogs)
                .extracting(WorkLog::getLogId)
                .containsExactly(freeLog.getLogId());
        assertThat(freeMechanicUser.getMechanicProfile().getClubs()).isEmpty();
        assertThat(clubStaffRepository.findByUserUserId(freeMechanicUser.getUserId())).isEmpty();
    }
}

