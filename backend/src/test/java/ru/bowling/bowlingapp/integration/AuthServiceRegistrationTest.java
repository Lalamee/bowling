package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.BowlingClubDTO;
import ru.bowling.bowlingapp.DTO.ManagerProfileDTO;
import ru.bowling.bowlingapp.DTO.MechanicProfileDTO;
import ru.bowling.bowlingapp.DTO.OwnerProfileDTO;
import ru.bowling.bowlingapp.DTO.RegisterUserDTO;
import ru.bowling.bowlingapp.Entity.AccountType;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.ClubStaff;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.AccountTypeRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.RoleRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Service.AuthService;

import java.time.LocalDate;
import java.util.Collections;
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
    void registerFreeMechanicCreatesPendingUserWithoutClubLinks() {
        Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow();
        AccountType freeAccount = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_BASIC.name()).orElseThrow();

        RegisterUserDTO dto = RegisterUserDTO.builder()
                .phone("+79998887766")
                .password("P@ssword123")
                .roleId(mechanicRole.getRoleId().intValue())
                .accountTypeId(freeAccount.getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("Свободный Механик")
                .birthDate(LocalDate.of(1990, 1, 1))
                .totalExperienceYears(6)
                .bowlingExperienceYears(3)
                .isEntrepreneur(true)
                .region("Москва")
                .skills("диагностика")
                .advantages("оперативность")
                .build();

        authService.registerUser(dto, mechanicDto, null, null, null);

        User saved = userRepository.findByPhone("+79998887766").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo(RoleName.MECHANIC.name());
        assertThat(saved.getAccountType().getName()).isEqualTo(AccountTypeName.FREE_MECHANIC_BASIC.name());
        assertThat(saved.getIsActive()).isFalse();
        assertThat(saved.getIsVerified()).isFalse();

        MechanicProfile profile = saved.getMechanicProfile();
        assertThat(profile).isNotNull();
        assertThat(profile.getRegion()).isEqualTo("Москва");
        assertThat(profile.getClubs()).isEmpty();

        List<ClubStaff> clubStaff = clubStaffRepository.findByUserUserIdAndIsActiveTrue(saved.getUserId());
        assertThat(clubStaff).isEmpty();
    }

    @Test
    void registerClubMechanicCreatesLinksToClubAndStaff() {
        Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow();
        AccountType individual = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name()).orElseThrow();

        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Strike Club")
                .address("Test street 1")
                .lanesCount(12)
                .isActive(true)
                .isVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        RegisterUserDTO dto = RegisterUserDTO.builder()
                .phone("+79998880001")
                .password("ClubPass123")
                .roleId(mechanicRole.getRoleId().intValue())
                .accountTypeId(individual.getAccountTypeId().intValue())
                .build();

        MechanicProfileDTO mechanicDto = MechanicProfileDTO.builder()
                .fullName("Клубный механик")
                .birthDate(LocalDate.of(1992, 2, 2))
                .totalExperienceYears(4)
                .bowlingExperienceYears(2)
                .isEntrepreneur(false)
                .region("Санкт-Петербург")
                .clubId(club.getClubId())
                .build();

        authService.registerUser(dto, mechanicDto, null, null, null);

        User saved = userRepository.findByPhone("+79998880001").orElseThrow();
        assertThat(saved.getRole().getName()).isEqualTo(RoleName.MECHANIC.name());
        assertThat(saved.getAccountType().getName()).isEqualTo(AccountTypeName.INDIVIDUAL.name());
        assertThat(saved.getIsActive()).isTrue();

        MechanicProfile profile = saved.getMechanicProfile();
        assertThat(profile).isNotNull();
        assertThat(profile.getClubs()).extracting(BowlingClub::getClubId).containsExactly(club.getClubId());

        List<ClubStaff> staffRecords = clubStaffRepository.findByUserUserIdAndIsActiveTrue(saved.getUserId());
        assertThat(staffRecords).hasSize(1);
        assertThat(staffRecords.get(0).getClub().getClubId()).isEqualTo(club.getClubId());
        assertThat(staffRecords.get(0).getRole().getName()).isEqualTo(RoleName.MECHANIC.name());
    }

    @Test
    void registerOwnerManagerAndAdminRespectAccountMappings() {
        Role ownerRole = roleRepository.findByNameIgnoreCase(RoleName.CLUB_OWNER.name()).orElseThrow();
        Role managerRole = roleRepository.findByNameIgnoreCase(RoleName.HEAD_MECHANIC.name()).orElseThrow();
        Role adminRole = roleRepository.findByNameIgnoreCase(RoleName.ADMIN.name()).orElseThrow();

        AccountType ownerType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.CLUB_OWNER.name()).orElseThrow();
        AccountType managerType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.CLUB_MANAGER.name()).orElseThrow();
        AccountType adminType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.MAIN_ADMIN.name()).orElseThrow();

        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Galaxy")
                .address("Universe ave 5")
                .lanesCount(8)
                .isActive(true)
                .isVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        RegisterUserDTO ownerDto = RegisterUserDTO.builder()
                .phone("+79990001122")
                .password("OwnerPass123")
                .roleId(ownerRole.getRoleId().intValue())
                .accountTypeId(ownerType.getAccountTypeId().intValue())
                .build();

        OwnerProfileDTO ownerProfileDTO = OwnerProfileDTO.builder()
                .inn("7701234567")
                .legalName("ООО \"БоулПолис\"")
                .contactPerson("Владелец Клуба")
                .contactPhone("+79990001122")
                .build();

        BowlingClubDTO clubDTO = BowlingClubDTO.builder()
                .name(club.getName())
                .address(club.getAddress())
                .lanesCount(10)
                .contactPhone(club.getContactPhone())
                .contactEmail(club.getContactEmail())
                .equipmentTypes(Collections.emptyList())
                .build();

        authService.registerUser(ownerDto, null, ownerProfileDTO, null, clubDTO);

        User ownerUser = userRepository.findByPhone("+79990001122").orElseThrow();
        assertThat(ownerUser.getRole().getName()).isEqualTo(RoleName.CLUB_OWNER.name());
        assertThat(ownerUser.getAccountType().getName()).isEqualTo(AccountTypeName.CLUB_OWNER.name());
        assertThat(ownerUser.getIsActive()).isFalse();
        OwnerProfile ownerProfile = ownerUser.getOwnerProfile();
        assertThat(ownerProfile).isNotNull();

        RegisterUserDTO managerRegister = RegisterUserDTO.builder()
                .phone("+79995550000")
                .password("Manager123")
                .roleId(managerRole.getRoleId().intValue())
                .accountTypeId(managerType.getAccountTypeId().intValue())
                .build();

        ManagerProfileDTO managerProfileDTO = ManagerProfileDTO.builder()
                .fullName("Менеджер Клуба")
                .contactPhone("+79995550000")
                .clubId(club.getClubId())
                .build();

        authService.registerUser(managerRegister, null, null, managerProfileDTO, null);

        User managerUser = userRepository.findByPhone("+79995550000").orElseThrow();
        assertThat(managerUser.getRole().getName()).isEqualTo(RoleName.HEAD_MECHANIC.name());
        assertThat(managerUser.getAccountType().getName()).isEqualTo(AccountTypeName.CLUB_MANAGER.name());
        assertThat(managerUser.getIsActive()).isFalse();
        ClubStaff managerStaff = clubStaffRepository.findByClubAndUser(club, managerUser).orElse(null);
        assertThat(managerStaff).isNotNull();
        assertThat(managerStaff.getRole().getName()).isEqualTo(RoleName.HEAD_MECHANIC.name());

        RegisterUserDTO adminRegister = RegisterUserDTO.builder()
                .phone("+79997770000")
                .password("AdminPass123")
                .roleId(adminRole.getRoleId().intValue())
                .accountTypeId(adminType.getAccountTypeId().intValue())
                .build();

        authService.registerUser(adminRegister, null, ownerProfileDTO, null, null);

        User adminUser = userRepository.findByPhone("+79997770000").orElseThrow();
        assertThat(adminUser.getRole().getName()).isEqualTo(RoleName.ADMIN.name());
        assertThat(adminUser.getAccountType().getName()).isEqualTo(AccountTypeName.MAIN_ADMIN.name());
        assertThat(adminUser.getIsActive()).isTrue();
        assertThat(adminUser.getIsVerified()).isTrue();
    }
}
