package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class AuthServiceRegistrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private ManagerProfileRepository managerProfileRepository;

    @Autowired
    private OwnerProfileRepository ownerProfileRepository;

    @Autowired
    private AdministratorProfileRepository administratorProfileRepository;

    @Autowired
    private AttestationApplicationRepository attestationApplicationRepository;

    @BeforeEach
    void setUp() {
        attestationApplicationRepository.deleteAll();
        clubStaffRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
        managerProfileRepository.deleteAll();
        administratorProfileRepository.deleteAll();
        ownerProfileRepository.deleteAll();
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
                AccountType.builder().name("INDIVIDUAL").build(),
                AccountType.builder().name("CLUB_OWNER").build(),
                AccountType.builder().name("CLUB_MANAGER").build(),
                AccountType.builder().name("FREE_MECHANIC_BASIC").build(),
                AccountType.builder().name("FREE_MECHANIC_PREMIUM").build(),
                AccountType.builder().name("MAIN_ADMIN").build()
        ));
    }

    @Test
    void freeMechanicRegistrationCreatesProfileWithoutClubLinks() {
        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000001")
                .password("password1")
                .roleId(getRoleId("MECHANIC"))
                .accountTypeId(getAccountTypeId("FREE_MECHANIC_BASIC"))
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("Свободный Механик")
                .birthDate(LocalDate.of(1990, 1, 1))
                .totalExperienceYears(5)
                .bowlingExperienceYears(3)
                .build();

        authService.registerUser(registerDto, mechanicDto, null, null, null);

        User saved = userRepository.findByPhone("+79990000001").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo("MECHANIC");
        assertThat(saved.getAccountType().getName()).isEqualTo("FREE_MECHANIC_BASIC");
        assertThat(saved.getIsActive()).isFalse();
        assertThat(saved.getIsVerified()).isFalse();
        assertThat(saved.getMechanicProfile()).isNotNull();
        assertThat(saved.getMechanicProfile().getClubs()).isEmpty();
        assertThat(clubStaffRepository.findAll()).isEmpty();

        AttestationApplication application = attestationApplicationRepository
                .findFirstByMechanicProfile_ProfileIdOrderByUpdatedAtDesc(saved.getMechanicProfile().getProfileId())
                .orElseThrow();
        assertThat(application.getStatus()).isEqualTo(AttestationStatus.PENDING);
        assertThat(application.getComment()).containsIgnoringCase("Премиум").containsIgnoringCase("Базовый");
    }

    @Test
    void clubMechanicRegistrationCreatesStaffAndClubLink() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Test Club")
                .address("Address 1")
                .lanesCount(10)
                .isActive(true)
                .isVerified(false)
                .build());

        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000002")
                .password("password1")
                .roleId(getRoleId("MECHANIC"))
                .accountTypeId(getAccountTypeId("INDIVIDUAL"))
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("Клубный Механик")
                .birthDate(LocalDate.of(1991, 2, 2))
                .totalExperienceYears(7)
                .bowlingExperienceYears(4)
                .clubId(club.getClubId())
                .build();

        authService.registerUser(registerDto, mechanicDto, null, null, null);

        User saved = userRepository.findByPhone("+79990000002").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo("MECHANIC");
        assertThat(saved.getAccountType().getName()).isEqualTo("INDIVIDUAL");
        assertThat(saved.getMechanicProfile().getClubs()).extracting(BowlingClub::getClubId)
                .containsExactly(club.getClubId());

        List<ClubStaff> staff = clubStaffRepository.findAll();
        assertThat(staff).hasSize(1);
        assertThat(staff.get(0).getRole().getName()).isEqualTo("MECHANIC");
        assertThat(Boolean.TRUE.equals(staff.get(0).getIsActive())).isFalse();
    }

    @Test
    void clubManagerRegistrationCreatesStaffRecord() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Manager Club")
                .address("Address 2")
                .lanesCount(8)
                .isActive(true)
                .isVerified(false)
                .build());

        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000003")
                .password("password1")
                .roleId(getRoleId("HEAD_MECHANIC"))
                .accountTypeId(getAccountTypeId("CLUB_MANAGER"))
                .build();

        ManagerProfileDTO managerDto = ManagerProfileDTO.builder()
                .fullName("Менеджер Клуба")
                .clubId(club.getClubId())
                .build();

        authService.registerUser(registerDto, null, null, managerDto, null);

        User saved = userRepository.findByPhone("+79990000003").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo("HEAD_MECHANIC");
        assertThat(saved.getAccountType().getName()).isEqualTo("CLUB_MANAGER");
        assertThat(saved.getManagerProfile()).isNotNull();
        assertThat(saved.getManagerProfile().getClub().getClubId()).isEqualTo(club.getClubId());

        List<ClubStaff> staff = clubStaffRepository.findAll();
        assertThat(staff).hasSize(1);
        assertThat(staff.get(0).getRole().getName()).isEqualTo("HEAD_MECHANIC");
        assertThat(Boolean.TRUE.equals(staff.get(0).getIsActive())).isTrue();
    }

    @Test
    void clubOwnerRegistrationCreatesOwnerProfileAndClub() {
        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000004")
                .password("password1")
                .roleId(getRoleId("CLUB_OWNER"))
                .accountTypeId(getAccountTypeId("CLUB_OWNER"))
                .build();

        OwnerProfileDTO ownerDto = OwnerProfileDTO.builder()
                .inn("1234567890")
                .legalName("ООО Боулинг")
                .contactPerson("Владелец")
                .contactPhone("+79990000004")
                .build();

        BowlingClubDTO clubDto = BowlingClubDTO.builder()
                .name("Owner Club")
                .address("Address 3")
                .lanesCount(6)
                .build();

        authService.registerUser(registerDto, null, ownerDto, null, clubDto);

        User saved = userRepository.findByPhone("+79990000004").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo("CLUB_OWNER");
        assertThat(saved.getAccountType().getName()).isEqualTo("CLUB_OWNER");
        assertThat(saved.getOwnerProfile()).isNotNull();
        assertThat(saved.getOwnerProfile().getClubs()).hasSize(1);
        assertThat(bowlingClubRepository.findAll()).hasSize(1);
    }

    @Test
    void mainAdminRegistrationCreatesAdministratorProfile() {
        RegisterUserDTO registerDto = RegisterUserDTO.builder()
                .phone("+79990000005")
                .password("password1")
                .roleId(getRoleId("ADMIN"))
                .accountTypeId(getAccountTypeId("MAIN_ADMIN"))
                .build();

        authService.registerUser(registerDto, null, null, null, null);

        User saved = userRepository.findByPhone("+79990000005").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo("ADMIN");
        assertThat(saved.getAccountType().getName()).isEqualTo("MAIN_ADMIN");
        assertThat(saved.getAdministratorProfile()).isNotNull();
        assertThat(saved.getIsVerified()).isTrue();
    }

    private Integer getRoleId(String name) {
        return roleRepository.findByNameIgnoreCase(name)
                .map(role -> role.getRoleId().intValue())
                .orElseThrow();
    }

    private Integer getAccountTypeId(String name) {
        return accountTypeRepository.findByNameIgnoreCase(name)
                .map(type -> type.getAccountTypeId().intValue())
                .orElseThrow();
    }
}
