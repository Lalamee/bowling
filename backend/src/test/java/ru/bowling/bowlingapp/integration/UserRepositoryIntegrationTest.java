package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import ru.bowling.bowlingapp.Entity.AccountType;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Repository.AccountTypeRepository;
import ru.bowling.bowlingapp.Repository.RoleRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
public class UserRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Test
    void whenSaveAndRetrieveUser_thenCorrectMapping() {
        // Given
        Role role = new Role();
        role.setName("TEST_ROLE");
        Role savedRole = roleRepository.save(role);

        AccountType accountType = new AccountType();
        accountType.setName("TEST_ACCOUNT_TYPE");
        AccountType savedAccountType = accountTypeRepository.save(accountType);

        User user = User.builder()
                .phone("1234567890")
                .passwordHash("hashed_password")
                .role(savedRole)
                .accountType(savedAccountType)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();

        // When
        User savedUser = userRepository.save(user);
        User foundUser = userRepository.findById(savedUser.getUserId()).orElse(null);

        // Then
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getUserId()).isNotNull();
        assertThat(foundUser.getUserId()).isInstanceOf(Long.class);
        assertThat(foundUser.getPhone()).isEqualTo("1234567890");
        assertThat(foundUser.getRole()).isNotNull();
        assertThat(foundUser.getRole().getRoleId()).isEqualTo(savedRole.getRoleId());
        assertThat(foundUser.getRole().getRoleId()).isInstanceOf(Long.class);
        assertThat(foundUser.getAccountType()).isNotNull();
        assertThat(foundUser.getAccountType().getAccountTypeId()).isEqualTo(savedAccountType.getAccountTypeId());
        assertThat(foundUser.getAccountType().getAccountTypeId()).isInstanceOf(Long.class);
    }
}
