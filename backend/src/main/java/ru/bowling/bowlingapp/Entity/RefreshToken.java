package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "refresh_tokens", indexes = {
        @Index(name = "idx_refresh_token_hash", columnList = "token_hash", unique = true),
        @Index(name = "idx_refresh_token_user", columnList = "user_id")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RefreshToken {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        @Column(name = "refresh_token_id")
        private Long id;

        @ManyToOne(fetch = FetchType.LAZY, optional = false)
        @JoinColumn(name = "user_id", nullable = false)
        private User user;

        @Column(name = "token_hash", nullable = false, length = 128)
        private String tokenHash;

        @Column(name = "issued_at", nullable = false)
        private LocalDateTime issuedAt;

        @Column(name = "expires_at", nullable = false)
        private LocalDateTime expiresAt;

        @Column(name = "revoked", nullable = false)
        private boolean revoked;

        @Column(name = "revoked_at")
        private LocalDateTime revokedAt;

        @Column(name = "revocation_reason")
        private String revocationReason;

        @Column(name = "replaced_by_token_hash", length = 128)
        private String replacedByTokenHash;
}
