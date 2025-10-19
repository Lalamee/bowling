package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.PasswordResetToken;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
	Optional<PasswordResetToken> findByTokenAndUsedFalse(String token);
	Optional<PasswordResetToken> findTopByUser_UserIdOrderByCreatedAtDesc(Long userId);
	long countByUser_UserIdAndCreatedAtAfter(Long userId, LocalDateTime after);
} 