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
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Service.AuthService;
import ru.bowling.bowlingapp.Service.WorkLogService;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.DTO.WorkLogSearchDTO;
import ru.bowling.bowlingapp.Entity.WorkLog;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class MechanicAccessIntegrationTest {

    @Autowired
    private AuthService authService;
    @Autowired
    private WorkLogService workLogService;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private AccountTypeRepository accountTypeRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;
    @Autowired
    private BowlingClubRepository bowlingClubRepository;
    @Autowired
    private ClubStaffRepository clubStaffRepository;
    @Autowired
    private WorkLogRepository workLogRepository;
    @Autowired
    private ClubInvitationRepository clubInvitationRepository;

    @BeforeEach
    void init() {
        clubInvitationRepository.deleteAll();
        clubStaffRepository.deleteAll();
        workLogRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
        bowlingClubRepository.deleteAll();
        userRepository.deleteAll();
        accountTypeRepository.deleteAll();
        roleRepository.deleteAll();

        roleRepository.saveAll(List.of(
                Role.builder().name("ADMIN").build(),
                Role.builder().name("MECHANIC").build(),
                Role.builder().name("HEAD_MECHANIC").build(),
                Role.builder().name("CLUB_OWNER").build()
        ));

        accountTypeRepository.saveAll(List.of(
                AccountType.builder().name(AccountTypeName.INDIVIDUAL.name()).build(),
                AccountType.builder().name(AccountTypeName.FREE_MECHANIC_BASIC.name()).build(),
                AccountType.builder().name(AccountTypeName.FREE_MECHANIC_PREMIUM.name()).build(),
                AccountType.builder().name(AccountTypeName.CLUB_OWNER.name()).build(),
                AccountType.builder().name(AccountTypeName.CLUB_MANAGER.name()).build(),
                AccountType.builder().name(AccountTypeName.MAIN_ADMIN.name()).build()
        ));
    }

    @Test
    void freeEntrepreneurRegistersWithoutClubLinks() {
        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79991234567")
                .password("password1")
                .roleId(roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow().getRoleId().intValue())
                .accountTypeId(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_PREMIUM.name()).orElseThrow().getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("ИП Свободный")
                .birthDate(LocalDate.of(1991, 2, 3))
                .totalExperienceYears(6)
                .bowlingExperienceYears(4)
                .isEntrepreneur(true)
                .build();

        authService.registerUser(registerDto, mechanicDto, null, null, null);

        User user = userRepository.findByPhone("+79991234567").orElseThrow();
        assertThat(user.getAccountType().getName()).isEqualTo(AccountTypeName.FREE_MECHANIC_PREMIUM.name());
        assertThat(user.getMechanicProfile().getIsEntrepreneur()).isTrue();
        assertThat(user.getMechanicProfile().getClubs()).isEmpty();
        assertThat(clubStaffRepository.findAll()).isEmpty();
    }

    @Test
    void clubMechanicRegistersWithStaffRecords() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Клуб А")
                .address("Адрес 1")
                .lanesCount(10)
                .isActive(true)
                .build());

        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000003")
                .password("password1")
                .roleId(roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow().getRoleId().intValue())
                .accountTypeId(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name()).orElseThrow().getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("Штатный Механик")
                .birthDate(LocalDate.of(1990, 5, 6))
                .totalExperienceYears(7)
                .bowlingExperienceYears(5)
                .clubId(club.getClubId())
                .build();

        authService.registerUser(registerDto, mechanicDto, null, null, null);

        User user = userRepository.findByPhone("+79990000003").orElseThrow();
        assertThat(user.getMechanicProfile().getClubs()).extracting(BowlingClub::getClubId).containsExactly(club.getClubId());
        List<ClubStaff> staff = clubStaffRepository.findAll();
        assertThat(staff).hasSize(1);
        assertThat(staff.get(0).getIsActive()).isTrue();
        assertThat(staff.get(0).getClub().getClubId()).isEqualTo(club.getClubId());
    }

    @Test
    void mechanicsSeeOnlyAccessibleWorkLogs() {
        BowlingClub clubA = bowlingClubRepository.save(BowlingClub.builder()
                .name("Клуб А")
                .address("Адрес 1")
                .lanesCount(6)
                .isActive(true)
                .build());
        BowlingClub clubB = bowlingClubRepository.save(BowlingClub.builder()
                .name("Клуб B")
                .address("Адрес 2")
                .lanesCount(8)
                .isActive(true)
                .build());

        // штатный механик клуба A
        RegisterUserDTO staffDto = RegisterUserDTO.builder()
                .phone("+79993330001")
                .password("password1")
                .roleId(roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow().getRoleId().intValue())
                .accountTypeId(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name()).orElseThrow().getAccountTypeId().intValue())
                .build();
        MechanicProfileDTO staffProfile = MechanicProfileDTO.builder()
                .fullName("Штатный")
                .birthDate(LocalDate.of(1990, 1, 1))
                .totalExperienceYears(5)
                .bowlingExperienceYears(3)
                .clubId(clubA.getClubId())
                .build();
        authService.registerUser(staffDto, staffProfile, null, null, null);
        User staffUser = userRepository.findByPhone("+79993330001").orElseThrow();

        // свободный премиум механик с приглашением в клуб B
        RegisterUserDTO freeDto = RegisterUserDTO.builder()
                .phone("+79994440002")
                .password("password1")
                .roleId(roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow().getRoleId().intValue())
                .accountTypeId(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_PREMIUM.name()).orElseThrow().getAccountTypeId().intValue())
                .build();
        MechanicProfileDTO freeProfile = MechanicProfileDTO.builder()
                .fullName("Свободный")
                .birthDate(LocalDate.of(1992, 2, 2))
                .totalExperienceYears(4)
                .bowlingExperienceYears(2)
                .isEntrepreneur(true)
                .build();
        authService.registerUser(freeDto, freeProfile, null, null, null);
        User freeUser = userRepository.findByPhone("+79994440002").orElseThrow();

        clubInvitationRepository.save(ClubInvitation.builder()
                .club(clubB)
                .mechanic(freeUser)
                .status("ACCEPTED")
                .build());

        WorkLog logA = workLogRepository.save(WorkLog.builder()
                .club(clubA)
                .laneNumber(1)
                .status(WorkLogStatus.CREATED)
                .createdDate(LocalDateTime.now())
                .createdBy(staffUser.getUserId())
                .build());

        WorkLog logB = workLogRepository.save(WorkLog.builder()
                .club(clubB)
                .laneNumber(2)
                .status(WorkLogStatus.CREATED)
                .createdDate(LocalDateTime.now())
                .createdBy(freeUser.getUserId())
                .build());

        List<Long> staffVisible = workLogService.searchWorkLogs(new WorkLogSearchDTO(), staffUser.getUserId()).getContent()
                .stream().map(WorkLog::getLogId).toList();
        assertThat(staffVisible).contains(logA.getLogId()).doesNotContain(logB.getLogId());

        List<Long> freeVisible = workLogService.searchWorkLogs(new WorkLogSearchDTO(), freeUser.getUserId()).getContent()
                .stream().map(WorkLog::getLogId).toList();
        assertThat(freeVisible).contains(logB.getLogId()).doesNotContain(logA.getLogId());
    }
}
