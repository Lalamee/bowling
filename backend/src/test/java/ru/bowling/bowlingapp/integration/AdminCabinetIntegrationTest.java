package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.AdminCabinetService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class AdminCabinetIntegrationTest {

    @Autowired
    private AdminCabinetService adminCabinetService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private PersonalWarehouseRepository personalWarehouseRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private SupplierReviewRepository supplierReviewRepository;

    @Autowired
    private RequestPartRepository requestPartRepository;

    @Autowired
    private MaintenanceRequestRepository maintenanceRequestRepository;

    @Autowired
    private AttestationApplicationRepository attestationApplicationRepository;

    private Role mechanicRole;
    private AccountType freeBasic;
    private AccountType freePremium;

    @BeforeEach
    void setup() {
        requestPartRepository.deleteAll();
        maintenanceRequestRepository.deleteAll();
        supplierReviewRepository.deleteAll();
        clubStaffRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
        attestationApplicationRepository.deleteAll();
        bowlingClubRepository.deleteAll();
        userRepository.deleteAll();
        accountTypeRepository.deleteAll();
        roleRepository.deleteAll();

        mechanicRole = roleRepository.save(Role.builder().name(RoleName.MECHANIC.name()).build());
        roleRepository.save(Role.builder().name(RoleName.ADMIN.name()).build());
        roleRepository.save(Role.builder().name(RoleName.HEAD_MECHANIC.name()).build());
        roleRepository.save(Role.builder().name(RoleName.CLUB_OWNER.name()).build());

        freeBasic = accountTypeRepository.save(AccountType.builder().name(AccountTypeName.FREE_MECHANIC_BASIC.name()).build());
        freePremium = accountTypeRepository.save(AccountType.builder().name(AccountTypeName.FREE_MECHANIC_PREMIUM.name()).build());
        accountTypeRepository.save(AccountType.builder().name(AccountTypeName.INDIVIDUAL.name()).build());
        accountTypeRepository.save(AccountType.builder().name(AccountTypeName.CLUB_MANAGER.name()).build());
        accountTypeRepository.save(AccountType.builder().name(AccountTypeName.CLUB_OWNER.name()).build());
        accountTypeRepository.save(AccountType.builder().name(AccountTypeName.MAIN_ADMIN.name()).build());
    }

    @Test
    void adminCabinetListsAndModeratesCoreStreams() {
        User mechanicUser = userRepository.save(User.builder()
                .phone("+79995550111")
                .passwordHash("pwd")
                .role(mechanicRole)
                .accountType(freeBasic)
                .registrationDate(LocalDate.now())
                .isActive(false)
                .isVerified(false)
                .build());

        MechanicProfile profile = mechanicProfileRepository.save(MechanicProfile.builder()
                .user(mechanicUser)
                .fullName("Свободный Агент")
                .isDataVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());
        mechanicUser.setMechanicProfile(profile);
        userRepository.save(mechanicUser);

        AttestationApplication attestation = attestationApplicationRepository.save(AttestationApplication.builder()
                .user(mechanicUser)
                .mechanicProfile(profile)
                .status(AttestationStatus.NEW)
                .comment("Новая заявка на проверку")
                .submittedAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build());

        List<AdminRegistrationApplicationDTO> registrations = adminCabinetService.listRegistrationApplications();
        assertThat(registrations).extracting(AdminRegistrationApplicationDTO::getUserId).contains(mechanicUser.getUserId());

        AdminRegistrationApplicationDTO approved = adminCabinetService.approveRegistration(mechanicUser.getUserId());
        assertThat(approved.getIsVerified()).isTrue();
        assertThat(approved.getIsProfileVerified()).isTrue();
        assertThat(personalWarehouseRepository.findByMechanicProfile_ProfileIdAndIsActiveTrue(profile.getProfileId())).isNotEmpty();

        AdminRegistrationApplicationDTO upgraded = adminCabinetService.updateFreeMechanicAccount(mechanicUser.getUserId(),
                AdminAccountUpdateDTO.builder().accountTypeName(freePremium.getName()).accessLevelName("PREMIUM").build());
        assertThat(upgraded.getAccountType()).isEqualTo(AccountTypeName.FREE_MECHANIC_PREMIUM.name());

        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Admin Test Club")
                .lanesCount(6)
                .isActive(true)
                .isVerified(true)
                .createdAt(LocalDate.now())
                .build());

        AdminRegistrationApplicationDTO linked = adminCabinetService.changeMechanicClubLink(profile.getProfileId(),
                MechanicClubLinkRequestDTO.builder().clubId(club.getClubId()).attach(true).build());
        assertThat(linked.getClubId()).isEqualTo(club.getClubId());
        assertThat(clubStaffRepository.existsByClubAndUserAndIsActiveTrue(club, mechanicUser)).isTrue();

        SupplierReview review = supplierReviewRepository.save(SupplierReview.builder()
                .supplierId(1L)
                .clubId(club.getClubId())
                .userId(mechanicUser.getUserId())
                .rating(2)
                .isComplaint(true)
                .complaintStatus(SupplierComplaintStatus.DRAFT)
                .complaintTitle("Недопоставка")
                .reviewDate(LocalDateTime.now())
                .build());

        List<AdminComplaintDTO> complaints = adminCabinetService.listSupplierComplaints();
        assertThat(complaints).extracting(AdminComplaintDTO::getReviewId).contains(review.getReviewId());

        AdminComplaintDTO updatedComplaint = adminCabinetService.updateComplaintStatus(review.getReviewId(), SupplierComplaintStatus.IN_PROGRESS, false, "Разбираемся");
        assertThat(updatedComplaint.getComplaintStatus()).isEqualTo(SupplierComplaintStatus.IN_PROGRESS.name());

        MaintenanceRequest request = maintenanceRequestRepository.save(MaintenanceRequest.builder()
                .club(club)
                .laneNumber(1)
                .mechanic(profile)
                .requestDate(LocalDateTime.now())
                .status(MaintenanceRequestStatus.NEW)
                .build());

        requestPartRepository.save(RequestPart.builder()
                .request(request)
                .partName("Деталь помощи")
                .helpRequested(true)
                .status(ru.bowling.bowlingapp.Entity.enums.PartStatus.PENDING)
                .build());

        List<AdminHelpRequestDTO> helpRequests = adminCabinetService.listHelpRequests();
        assertThat(helpRequests).hasSize(1);
        assertThat(helpRequests.get(0).getRequestId()).isEqualTo(request.getRequestId());

        List<AttestationApplicationDTO> attestationList = adminCabinetService.listAttestationApplications();
        assertThat(attestationList).extracting(AttestationApplicationDTO::getApplicationId).contains(attestation.getApplicationId());
    }
}

