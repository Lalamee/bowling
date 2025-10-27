package ru.bowling.bowlingapp.Config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;
import org.springframework.test.util.ReflectionTestUtils;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Security.UserPrincipal;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private JwtTokenProvider provider;

    @BeforeEach
    void setUp() {
        provider = new JwtTokenProvider();
        ReflectionTestUtils.setField(provider, "secret", "test-secret");
        ReflectionTestUtils.setField(provider, "accessTokenValidity", 3_600_000L);
        ReflectionTestUtils.setField(provider, "refreshTokenValidity", 7_200_000L);
        provider.init();
    }

    @Test
    void authenticationContainsUserPrincipalWithIdAndRole() {
        Role role = new Role();
        role.setName("MECHANIC");

        User user = User.builder()
                .userId(123L)
                .phone("+70000000000")
                .role(role)
                .isActive(true)
                .build();

        String token = provider.generateAccessToken(user);
        Authentication authentication = provider.getAuthentication(token);

        assertThat(authentication.getPrincipal()).isInstanceOf(UserPrincipal.class);
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        assertThat(principal.getId()).isEqualTo(123L);
        assertThat(principal.getPhone()).isEqualTo("+70000000000");
        assertThat(authentication.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_MECHANIC");
    }
}
