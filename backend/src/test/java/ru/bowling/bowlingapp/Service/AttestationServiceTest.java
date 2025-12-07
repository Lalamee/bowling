package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.DTO.AttestationDecisionDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class AttestationServiceTest {

    @Autowired
    private AttestationService attestationService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private AttestationApplicationRepository attestationApplicationRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @BeforeEach
    void setUp() {
        attestationApplicationRepository.deleteAll();
        mechanicProfileRepository.deleteAll();
        userRepository.deleteAll();
        accountTypeRepository.deleteAll();
        roleRepository.deleteAll();

        roleRepository.saveAll(List.of(
                Role.builder().name("MECHANIC").build(),
                Role.builder().name("ADMIN").build()
        ));

        accountTypeRepository.saveAll(List.of(
                AccountType.builder().name("FREE_MECHANIC_BASIC").build(),
                AccountType.builder().name("MAIN_ADMIN").build()
        ));
    }

    @Test
    void submittingAttestationMarksPendingAndPersistsRequestedGrade() {
        MechanicProfile profile = createActiveMechanic("+79990000001", "Опытный Механик");

        AttestationApplicationDTO dto = AttestationApplicationDTO.builder()
                .userId(profile.getUser().getUserId())
                .mechanicProfileId(profile.getProfileId())
                .requestedGrade(MechanicGrade.MIDDLE)
                .comment("Прошу повысить грейд")
                .build();

        AttestationApplicationDTO saved = attestationService.submitApplication(dto);

        assertThat(saved.getStatus()).isEqualTo(AttestationDecisionStatus.PENDING);
        assertThat(saved.getRequestedGrade()).isEqualTo(MechanicGrade.MIDDLE);
        assertThat(attestationApplicationRepository.findAll()).hasSize(1);
        MechanicProfile reloaded = mechanicProfileRepository.findById(profile.getProfileId()).orElseThrow();
        assertThat(reloaded.getIsCertified()).isFalse();
    }

    @Test
    void rejectingRequiresReason() {
        MechanicProfile profile = createActiveMechanic("+79990000002", "Отказной Механик");
        AttestationApplicationDTO dto = AttestationApplicationDTO.builder()
                .userId(profile.getUser().getUserId())
                .mechanicProfileId(profile.getProfileId())
                .requestedGrade(MechanicGrade.JUNIOR)
                .build();
        AttestationApplicationDTO saved = attestationService.submitApplication(dto);

        AttestationDecisionDTO rejection = AttestationDecisionDTO.builder()
                .status(AttestationDecisionStatus.REJECTED)
                .comment("")
                .build();

        assertThatThrownBy(() -> attestationService.updateStatus(saved.getId(), rejection))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Comment is required");
    }

    @Test
    void approvalMarksProfileVerified() {
        MechanicProfile profile = createActiveMechanic("+79990000003", "Одобренный Механик");
        AttestationApplicationDTO dto = AttestationApplicationDTO.builder()
                .userId(profile.getUser().getUserId())
                .mechanicProfileId(profile.getProfileId())
                .requestedGrade(MechanicGrade.SENIOR)
                .build();
        AttestationApplicationDTO saved = attestationService.submitApplication(dto);

        AttestationDecisionDTO approval = AttestationDecisionDTO.builder()
                .status(AttestationDecisionStatus.APPROVED)
                .comment("Документы подтверждены")
                .approvedGrade(MechanicGrade.LEAD)
                .build();

        AttestationApplicationDTO decided = attestationService.updateStatus(saved.getId(), approval);
        MechanicProfile reloaded = mechanicProfileRepository.findById(profile.getProfileId()).orElseThrow();

        assertThat(decided.getStatus()).isEqualTo(AttestationDecisionStatus.APPROVED);
        assertThat(decided.getRequestedGrade()).isEqualTo(MechanicGrade.LEAD);
        assertThat(reloaded.getIsDataVerified()).isTrue();
        assertThat(reloaded.getVerificationDate()).isEqualTo(LocalDate.now());
        assertThat(reloaded.getIsCertified()).isTrue();
        assertThat(reloaded.getCertifiedGrade()).isEqualTo(MechanicGrade.LEAD);
    }

    private MechanicProfile createActiveMechanic(String phone, String name) {
        Role mechanicRole = roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow();
        AccountType accountType = accountTypeRepository.findByNameIgnoreCase("FREE_MECHANIC_BASIC").orElseThrow();

        User user = User.builder()
                .phone(phone)
                .passwordHash("secret")
                .role(mechanicRole)
                .accountType(accountType)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .lastModified(LocalDateTime.now())
                .build();

        MechanicProfile profile = MechanicProfile.builder()
                .user(user)
                .fullName(name)
                .region("Москва")
                .totalExperienceYears(5)
                .bowlingExperienceYears(3)
                .isEntrepreneur(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build();
        user.setMechanicProfile(profile);

        userRepository.save(user);
        mechanicProfileRepository.save(profile);
        return profile;
    }
}
