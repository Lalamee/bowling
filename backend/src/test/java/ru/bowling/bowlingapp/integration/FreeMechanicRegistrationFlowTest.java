package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationRequestDTO;
import ru.bowling.bowlingapp.DTO.MechanicApplicationDecisionDTO;
import ru.bowling.bowlingapp.Entity.AccountType;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.AccountTypeRepository;
import ru.bowling.bowlingapp.Repository.AttestationApplicationRepository;
import ru.bowling.bowlingapp.Repository.RoleRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Service.FreeMechanicApplicationService;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class FreeMechanicRegistrationFlowTest {

    @Autowired
    private FreeMechanicApplicationService applicationService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private AttestationApplicationRepository attestationApplicationRepository;

    @BeforeEach
    void setUpDictionaries() {
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
    void freeMechanicApplicationApprovedByAdminUpdatesAccountType() {
        FreeMechanicApplicationRequestDTO request = FreeMechanicApplicationRequestDTO.builder()
                .phone("+79991112233")
                .password("Mechanic123")
                .fullName("Свободный Агент")
                .birthDate(LocalDate.of(1995, 5, 5))
                .totalExperienceYears(7)
                .bowlingExperienceYears(4)
                .isEntrepreneur(true)
                .region("Казань")
                .skills("ремонт, обслуживание")
                .advantages("быстрая реакция")
                .build();

        var application = applicationService.submitApplication(request);
        assertThat(application.getStatus()).isEqualTo(AttestationStatus.NEW);
        assertThat(application.getAccountType()).isEqualTo(AccountTypeName.FREE_MECHANIC_BASIC.name());

        MechanicApplicationDecisionDTO decision = MechanicApplicationDecisionDTO.builder()
                .targetAccountType(AccountTypeName.FREE_MECHANIC_PREMIUM.name())
                .comment("Повышение до премиум")
                .build();

        var approved = applicationService.approve(application.getApplicationId(), decision);
        assertThat(approved.getStatus()).isEqualTo(AttestationStatus.APPROVED);
        assertThat(approved.getAccountType()).isEqualTo(AccountTypeName.FREE_MECHANIC_PREMIUM.name());

        User user = userRepository.findByPhone("+79991112233").orElseThrow();
        assertThat(user.getIsActive()).isTrue();
        assertThat(user.getIsVerified()).isTrue();
        assertThat(user.getMechanicProfile()).isNotNull();
        assertThat(user.getMechanicProfile().getIsDataVerified()).isTrue();

        var applicationRecord = attestationApplicationRepository.findById(approved.getApplicationId()).orElseThrow();
        assertThat(applicationRecord.getStatus()).isEqualTo(AttestationStatus.APPROVED);
    }
}
