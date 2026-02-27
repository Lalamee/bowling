package ru.bowling.bowlingapp.Config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.io.IOException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class JwtTokenFilterTest {

    @Test
    void shouldSkipAuthForPublicEndpoint() throws ServletException, IOException {
        JwtTokenProvider provider = mock(JwtTokenProvider.class);
        JwtTokenFilter filter = new JwtTokenFilter(provider);

        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
        assertThat(response.getStatus()).isEqualTo(200);
    }

    @Test
    void shouldSetUnauthorizedForInvalidToken() throws ServletException, IOException {
        JwtTokenProvider provider = mock(JwtTokenProvider.class);
        JwtTokenFilter filter = new JwtTokenFilter(provider);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/users");
        request.addHeader("Authorization", "Bearer bad-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        when(provider.isValidToken("bad-token")).thenReturn(false);

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(401);
        assertThat(response.getContentAsString()).contains("Invalid or expired token");
    }

    @Test
    void shouldAuthenticateForValidToken() throws ServletException, IOException {
        JwtTokenProvider provider = mock(JwtTokenProvider.class);
        JwtTokenFilter filter = new JwtTokenFilter(provider);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/users");
        request.addHeader("Authorization", "Bearer ok-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        when(provider.isValidToken("ok-token")).thenReturn(true);
        when(provider.getAuthentication("ok-token")).thenReturn(
                new UsernamePasswordAuthenticationToken("user", null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN")))
        );

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
        assertThat(response.getStatus()).isEqualTo(200);
    }
}
