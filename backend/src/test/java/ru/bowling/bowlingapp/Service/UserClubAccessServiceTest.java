package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class UserClubAccessServiceTest {

    @Autowired
    private UserClubAccessService userClubAccessService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private AccountTypeRepository accountTypeRepository;
    @Autowired
    private BowlingClubRepository bowlingClubRepository;
    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;
    @Autowired
    private ClubStaffRepository clubStaffRepository;
    @Autowired
    private ClubInvitationRepository clubInvitationRepository;

    @BeforeEach
    void setUp() {
        clubInvitationRepository.deleteAll();
        clubStaffRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
        bowlingClubRepository.deleteAll();
        userRepository.deleteAll();
        accountTypeRepository.deleteAll();
        roleRepository.deleteAll();

        roleRepository.saveAll(List.of(
                Role.builder().name(RoleName.ADMIN.name()).build(),
                Role.builder().name(RoleName.MECHANIC.name()).build(),
                Role.builder().name(RoleName.HEAD_MECHANIC.name()).build(),
                Role.builder().name(RoleName.CLUB_OWNER.name()).build()
        ));

        accountTypeRepository.saveAll(List.of(
                AccountType.builder().name(AccountTypeName.MAIN_ADMIN.name()).build(),
                AccountType.builder().name(AccountTypeName.FREE_MECHANIC_BASIC.name()).build(),
                AccountType.builder().name(AccountTypeName.INDIVIDUAL.name()).build()
        ));
    }

    @Test
    void adminSeesAllClubs() {
        BowlingClub clubA = bowlingClubRepository.save(BowlingClub.builder()
                .name("Admin Club A")
                .address("A")
                .lanesCount(4)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());
        BowlingClub clubB = bowlingClubRepository.save(BowlingClub.builder()
                .name("Admin Club B")
                .address("B")
                .lanesCount(6)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        User admin = userRepository.save(User.builder()
                .phone("+79990001111")
                .passwordHash("hash")
                .role(roleRepository.findByNameIgnoreCase(RoleName.ADMIN.name()).orElseThrow())
                .accountType(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.MAIN_ADMIN.name()).orElseThrow())
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .lastModified(LocalDateTime.now())
                .build());

        List<Long> accessible = userClubAccessService.resolveAccessibleClubIds(admin);
        assertThat(accessible).containsExactlyInAnyOrder(clubA.getClubId(), clubB.getClubId());
    }

    @Test
    void freeMechanicSeesOnlyAcceptedInvites() {
        BowlingClub acceptedClub = bowlingClubRepository.save(BowlingClub.builder()
                .name("Invite Club A")
                .address("A")
                .lanesCount(4)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());
        BowlingClub pendingClub = bowlingClubRepository.save(BowlingClub.builder()
                .name("Invite Club B")
                .address("B")
                .lanesCount(8)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        User freeMech = userRepository.save(User.builder()
                .phone("+79995550303")
                .passwordHash("hash")
                .role(roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow())
                .accountType(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_BASIC.name()).orElseThrow())
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .lastModified(LocalDateTime.now())
                .build());

        MechanicProfile profile = mechanicProfileRepository.save(MechanicProfile.builder()
                .user(freeMech)
                .fullName("Свободный")
                .updatedAt(LocalDate.now())
                .createdAt(LocalDate.now())
                .isEntrepreneur(true)
                .build());

        clubInvitationRepository.save(ClubInvitation.builder()
                .club(acceptedClub)
                .mechanic(freeMech)
                .status("ACCEPTED")
                .build());
        clubInvitationRepository.save(ClubInvitation.builder()
                .club(pendingClub)
                .mechanic(freeMech)
                .status("PENDING")
                .build());

        List<Long> accessible = userClubAccessService.resolveAccessibleClubIds(freeMech);
        assertThat(accessible).containsExactly(acceptedClub.getClubId());
    }

    @Test
    void clubMechanicSeesOwnStaffClub() {
        BowlingClub staffClub = bowlingClubRepository.save(BowlingClub.builder()
                .name("Staff Club")
                .address("C")
                .lanesCount(5)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());
        BowlingClub otherClub = bowlingClubRepository.save(BowlingClub.builder()
                .name("Other Club")
                .address("D")
                .lanesCount(7)
                .isActive(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());

        User mechanic = userRepository.save(User.builder()
                .phone("+79994440303")
                .passwordHash("hash")
                .role(roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow())
                .accountType(accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name()).orElseThrow())
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .lastModified(LocalDateTime.now())
                .build());

        MechanicProfile profile = mechanicProfileRepository.save(MechanicProfile.builder()
                .user(mechanic)
                .fullName("Штатный")
                .updatedAt(LocalDate.now())
                .createdAt(LocalDate.now())
                .build());

        clubStaffRepository.save(ClubStaff.builder()
                .club(staffClub)
                .user(mechanic)
                .role(roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElseThrow())
                .assignedAt(LocalDateTime.now())
                .isActive(true)
                .infoAccessRestricted(false)
                .build());

        List<Long> accessible = userClubAccessService.resolveAccessibleClubIds(mechanic);
        assertThat(accessible).containsExactly(staffClub.getClubId()).doesNotContain(otherClub.getClubId());
    }
}
