package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationRequestDTO;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationResponseDTO;
import ru.bowling.bowlingapp.DTO.MechanicApplicationDecisionDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class FreeMechanicApplicationServiceTest {

    @Autowired
    private FreeMechanicApplicationService freeMechanicApplicationService;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private AttestationApplicationRepository attestationApplicationRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @BeforeEach
    void setUp() {
        clubStaffRepository.deleteAll();
        attestationApplicationRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
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
    void freeMechanicFlowCreatesApplicationAndAllowsAdminApproval() {
        FreeMechanicApplicationRequestDTO request = FreeMechanicApplicationRequestDTO.builder()
                .phone("+79995550001")
                .password("StrongPass1")
                .fullName("Иван Свободный")
                .birthDate(LocalDate.of(1992, 3, 4))
                .educationLevelId(1)
                .totalExperienceYears(6)
                .bowlingExperienceYears(4)
                .isEntrepreneur(true)
                .specializationId(2)
                .region("Москва")
                .skills("Диагностика, настройка дорожек")
                .advantages("Быстро реагирую на заявки")
                .build();

        FreeMechanicApplicationResponseDTO response = freeMechanicApplicationService.submitApplication(request);

        assertThat(response.getStatus()).isEqualTo(AttestationStatus.PENDING);
        assertThat(response.getApplicationId()).isNotNull();
        User createdUser = userRepository.findByPhone("+79995550001").orElseThrow();
        assertThat(createdUser.getIsActive()).isFalse();
        assertThat(createdUser.getIsVerified()).isFalse();
        assertThat(createdUser.getAccountType().getName()).isEqualTo("FREE_MECHANIC_BASIC");
        assertThat(createdUser.getMechanicProfile()).isNotNull();
        assertThat(createdUser.getMechanicProfile().getIsDataVerified()).isFalse();
        assertThat(attestationApplicationRepository.findAll()).hasSize(1);
        assertThat(clubStaffRepository.findAll()).isEmpty();

        MechanicApplicationDecisionDTO decision = MechanicApplicationDecisionDTO.builder()
                .targetAccountType("FREE_MECHANIC_PREMIUM")
                .comment("Документы подтверждены")
                .build();

        FreeMechanicApplicationResponseDTO approved = freeMechanicApplicationService.approve(response.getApplicationId(), decision);

        assertThat(approved.getStatus()).isEqualTo(AttestationStatus.APPROVED);
        User approvedUser = userRepository.findByPhone("+79995550001").orElseThrow();
        MechanicProfile profile = mechanicProfileRepository.findById(approvedUser.getMechanicProfile().getProfileId()).orElseThrow();

        assertThat(approvedUser.getIsActive()).isTrue();
        assertThat(approvedUser.getIsVerified()).isTrue();
        assertThat(approvedUser.getAccountType().getName()).isEqualTo("FREE_MECHANIC_PREMIUM");
        assertThat(profile.getIsDataVerified()).isTrue();
        assertThat(profile.getVerificationDate()).isNotNull();

        User authenticated = authService.authenticateUser("+79995550001", "StrongPass1");
        Map<String, Object> cabinet = authService.getCurrentUserInfo(authenticated.getPhone());
        assertThat(cabinet.get("accountType")).isEqualTo("FREE_MECHANIC_PREMIUM");
        assertThat(cabinet.get("mechanicProfile")).isNotNull();
    }
}

