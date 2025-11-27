package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;
import ru.bowling.bowlingapp.DTO.AttestationDecisionDTO;
import ru.bowling.bowlingapp.DTO.SpecialistCardDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.AttestationService;
import ru.bowling.bowlingapp.Service.MechanicDirectoryService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class AttestationIntegrationTest {

    @Autowired
    private AttestationService attestationService;

    @Autowired
    private MechanicDirectoryService mechanicDirectoryService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @BeforeEach
    void setup() {
        mechanicProfileRepository.deleteAll();
        userRepository.deleteAll();
        accountTypeRepository.deleteAll();
        roleRepository.deleteAll();

        roleRepository.save(Role.builder().name("MECHANIC").build());
        accountTypeRepository.save(AccountType.builder().name("FREE_MECHANIC_BASIC").build());
    }

    @Test
    void approvedAttestationMakesMechanicVisibleInSpecialistBase() {
        MechanicProfile profile = createMechanic("+79995554433", "Иван Аттестованный", 1, 4.5);

        AttestationApplicationDTO submission = attestationService.submitApplication(
                AttestationApplicationDTO.builder()
                        .userId(profile.getUser().getUserId())
                        .mechanicProfileId(profile.getProfileId())
                        .requestedGrade(MechanicGrade.SENIOR)
                        .comment("Готов работать с премиальными клубами")
                        .build()
        );

        AttestationDecisionDTO approval = AttestationDecisionDTO.builder()
                .status(AttestationDecisionStatus.APPROVED)
                .approvedGrade(MechanicGrade.SENIOR)
                .comment("Подтверждено администрацией")
                .build();

        attestationService.updateStatus(submission.getId(), approval);

        List<SpecialistCardDTO> cards = mechanicDirectoryService.getSpecialistBase("Москва", 1, MechanicGrade.SENIOR, 4.0);

        assertThat(cards).hasSize(1);
        SpecialistCardDTO card = cards.get(0);
        assertThat(card.getFullName()).isEqualTo("Иван Аттестованный");
        assertThat(card.getAttestedGrade()).isEqualTo(MechanicGrade.SENIOR);
        assertThat(card.getRegion()).contains("Москва");
        assertThat(card.getVerificationDate()).isNotNull();
    }

    private MechanicProfile createMechanic(String phone, String name, Integer specializationId, Double rating) {
        Role role = roleRepository.findByNameIgnoreCase("MECHANIC").orElseThrow();
        AccountType type = accountTypeRepository.findByNameIgnoreCase("FREE_MECHANIC_BASIC").orElseThrow();

        User user = User.builder()
                .phone(phone)
                .passwordHash("secret")
                .role(role)
                .accountType(type)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .lastModified(LocalDateTime.now())
                .build();

        MechanicProfile profile = MechanicProfile.builder()
                .user(user)
                .fullName(name)
                .specializationId(specializationId)
                .skills("Настройка дорожек")
                .advantages("Быстрая диагностика")
                .region("Москва")
                .rating(rating)
                .totalExperienceYears(8)
                .bowlingExperienceYears(5)
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
