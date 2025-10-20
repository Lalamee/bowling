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
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryIntegrationTest {

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
    void whenSaveUser_thenCanFindByPhoneAndEmailIgnoringCase() {
        Role role = new Role();
        role.setName("TEST_ROLE");
        Role savedRole = roleRepository.save(role);

        AccountType accountType = new AccountType();
        accountType.setName("TEST_ACCOUNT_TYPE");
        AccountType savedAccountType = accountTypeRepository.save(accountType);

        User user = User.builder()
                .phone("+79991234567")
                .email("owner@example.com")
                .passwordHash("hashed_password")
                .role(savedRole)
                .accountType(savedAccountType)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();

        User savedUser = userRepository.save(user);

        Optional<User> byPhone = userRepository.findByPhone("+79991234567");
        Optional<User> byEmailLower = userRepository.findByEmailIgnoreCase("owner@example.com");
        Optional<User> byEmailUpper = userRepository.findByEmailIgnoreCase("OWNER@EXAMPLE.COM");

        assertThat(byPhone).isPresent();
        assertThat(byPhone.get().getUserId()).isEqualTo(savedUser.getUserId());
        assertThat(byEmailLower).isPresent();
        assertThat(byEmailUpper).isPresent();
        assertThat(byEmailUpper.get().getUserId()).isEqualTo(savedUser.getUserId());
    }

    @Test
    void whenEmailExists_thenExistsByEmailReturnsTrue() {
        Role role = new Role();
        role.setName("ROLE_TWO");
        Role savedRole = roleRepository.save(role);

        AccountType accountType = new AccountType();
        accountType.setName("ACCOUNT_TWO");
        AccountType savedAccountType = accountTypeRepository.save(accountType);

        User user = User.builder()
                .phone("+79990000000")
                .email("second@example.com")
                .passwordHash("hashed_password")
                .role(savedRole)
                .accountType(savedAccountType)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(false)
                .build();

        userRepository.save(user);

        assertThat(userRepository.existsByEmailIgnoreCase("second@example.com")).isTrue();
        assertThat(userRepository.existsByEmailIgnoreCase("SECOND@example.com")).isTrue();
        assertThat(userRepository.existsByEmailIgnoreCase("missing@example.com")).isFalse();
    }
}
