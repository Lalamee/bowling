package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Config.JwtTokenProvider;
import ru.bowling.bowlingapp.Entity.RefreshToken;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Exception.InvalidRefreshTokenException;
import ru.bowling.bowlingapp.Repository.RefreshTokenRepository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

        private final RefreshTokenRepository refreshTokenRepository;
        private final JwtTokenProvider jwtTokenProvider;

        @Transactional
        public RefreshToken registerRefreshToken(User user, String refreshToken) {
                if (user == null) {
                        throw new InvalidRefreshTokenException("Пользователь для токена не найден");
                }
                if (refreshToken == null || refreshToken.isBlank()) {
                        throw new InvalidRefreshTokenException("Refresh токен отсутствует");
                }

                String tokenHash = hash(refreshToken);
                refreshTokenRepository.findByTokenHash(tokenHash).ifPresent(existing -> {
                        refreshTokenRepository.delete(existing);
                });

                var expirationDate = jwtTokenProvider.getExpirationDate(refreshToken);
                if (expirationDate == null) {
                        throw new InvalidRefreshTokenException("Не удалось определить срок действия refresh токена");
                }
                LocalDateTime expiresAt = LocalDateTime.ofInstant(expirationDate.toInstant(), ZoneOffset.UTC);

                RefreshToken entity = RefreshToken.builder()
                                .user(user)
                                .tokenHash(tokenHash)
                                .issuedAt(LocalDateTime.now(ZoneOffset.UTC))
                                .expiresAt(expiresAt)
                                .revoked(false)
                                .build();

                RefreshToken saved = refreshTokenRepository.save(entity);
                purgeExpiredTokens(user);
                return saved;
        }

        @Transactional(readOnly = true)
        public RefreshToken getValidToken(String refreshToken) {
                if (refreshToken == null || refreshToken.isBlank()) {
                        throw new InvalidRefreshTokenException("Refresh токен отсутствует");
                }

                String tokenHash = hash(refreshToken);
                RefreshToken stored = refreshTokenRepository.findByTokenHash(tokenHash)
                                .orElseThrow(() -> new InvalidRefreshTokenException("Refresh токен не зарегистрирован"));

                if (stored.isRevoked()) {
                        throw new InvalidRefreshTokenException("Refresh токен отозван");
                }

                if (stored.getExpiresAt() != null && stored.getExpiresAt().isBefore(LocalDateTime.now(ZoneOffset.UTC))) {
                        throw new InvalidRefreshTokenException("Срок действия refresh токена истёк");
                }

                return stored;
        }

        @Transactional
        public RefreshToken rotateToken(RefreshToken currentToken, String newRefreshToken) {
                if (currentToken == null) {
                        throw new InvalidRefreshTokenException("Токен для обновления не найден");
                }

                User user = currentToken.getUser();
                if (user == null) {
                        throw new InvalidRefreshTokenException("Не удалось определить пользователя refresh токена");
                }

                currentToken.setRevoked(true);
                currentToken.setRevokedAt(LocalDateTime.now(ZoneOffset.UTC));
                currentToken.setReplacedByTokenHash(hash(newRefreshToken));
                refreshTokenRepository.save(currentToken);

                return registerRefreshToken(user, newRefreshToken);
        }

        @Transactional
        public boolean revokeToken(String refreshToken, String reason) {
                if (refreshToken == null || refreshToken.isBlank()) {
                        return false;
                }
                String tokenHash = hash(refreshToken);
                return refreshTokenRepository.findByTokenHash(tokenHash).map(entity -> {
                        if (entity.isRevoked()) {
                                return false;
                        }
                        entity.setRevoked(true);
                        entity.setRevokedAt(LocalDateTime.now(ZoneOffset.UTC));
                        entity.setRevocationReason(reason);
                        refreshTokenRepository.save(entity);
                        return true;
                }).orElse(false);
        }

        private void purgeExpiredTokens(User user) {
                List<RefreshToken> expired = refreshTokenRepository
                                .findByUserAndExpiresAtBefore(user, LocalDateTime.now(ZoneOffset.UTC));
                if (!expired.isEmpty()) {
                        refreshTokenRepository.deleteAll(expired);
                }
        }

        private String hash(String token) {
                try {
                        MessageDigest digest = MessageDigest.getInstance("SHA-256");
                        byte[] hashed = digest.digest(token.getBytes(StandardCharsets.UTF_8));
                        return HexFormat.of().formatHex(hashed);
                } catch (NoSuchAlgorithmException e) {
                        log.error("SHA-256 algorithm not available", e);
                        throw new IllegalStateException("Не удалось подготовить refresh токен");
                }
        }
}
