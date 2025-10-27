package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.RefreshToken;
import ru.bowling.bowlingapp.Entity.User;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
        Optional<RefreshToken> findByTokenHash(String tokenHash);

        List<RefreshToken> findByUserAndRevokedFalse(User user);

        List<RefreshToken> findByUserAndExpiresAtBefore(User user, LocalDateTime threshold);
}
