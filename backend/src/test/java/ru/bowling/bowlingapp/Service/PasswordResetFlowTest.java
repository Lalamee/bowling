package ru.bowling.bowlingapp.Service;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class PasswordResetFlowTest {

	@Autowired
	private AuthService authService;

	@Test
	void testPasswordReset_userNotFound() {
		Assertions.assertThrows(IllegalArgumentException.class, () ->
				authService.resetPassword("nonexistent", "newStrongPassword"));
	}
}
