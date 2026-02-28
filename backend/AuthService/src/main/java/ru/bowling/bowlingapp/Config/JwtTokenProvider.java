package ru.bowling.bowlingapp.Config;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Security.UserPrincipal;

import java.util.Date;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access.expiration}")
    private long accessTokenValidity;

    @Value("${jwt.refresh.expiration}")
    private long refreshTokenValidity;

    private Algorithm algorithm;

    @PostConstruct
    public void init() {
        algorithm = Algorithm.HMAC256(secret);
    }

    public String generateAccessToken(User user) {
        return JWT.create()
                .withSubject(user.getPhone())
                .withClaim("userId", String.valueOf(user.getUserId()))
                .withClaim("role", user.getRole() != null ? user.getRole().getName() : "USER")
                .withExpiresAt(new Date(System.currentTimeMillis() + accessTokenValidity))
                .sign(algorithm);
    }

    public String generateRefreshToken(User user) {
        return JWT.create()
                .withSubject(user.getPhone())
                .withExpiresAt(new Date(System.currentTimeMillis() + refreshTokenValidity))
                .sign(algorithm);
    }

    public Authentication getAuthentication(String token) {
        DecodedJWT decoded = JWT.require(algorithm).build().verify(token);
        String phone = decoded.getSubject();
        String role = decoded.getClaim("role").asString();
        String userIdClaim = decoded.getClaim("userId").asString();

        if (role == null || role.isBlank()) {
            role = "USER";
        }

        Long userId = null;
        if (userIdClaim != null && !userIdClaim.isBlank()) {
            try {
                userId = Long.parseLong(userIdClaim);
            } catch (NumberFormatException ignored) {
                userId = null;
            }
        }

        UserPrincipal principal = UserPrincipal.fromClaims(userId, phone, role);

        return new UsernamePasswordAuthenticationToken(
                principal,
                null,
                principal.getAuthorities()
        );
    }

    public boolean isValidToken(String token) {
        try {
            JWT.require(algorithm).build().verify(token);
            return true;
        } catch (JWTVerificationException e) {
            return false;
        }
    }

    public String getPhoneFromToken(String token) {
        try {
            DecodedJWT decoded = JWT.require(algorithm).build().verify(token);
            return decoded.getSubject();
        } catch (JWTVerificationException e) {
            throw new IllegalArgumentException("Invalid JWT token", e);
        }
    }
    
    public String getUserIdFromToken(String token) {
        try {
            DecodedJWT decoded = JWT.require(algorithm).build().verify(token);
            return decoded.getClaim("userId").asString();
        } catch (JWTVerificationException e) {
            throw new IllegalArgumentException("Invalid JWT token", e);
        }
    }
}