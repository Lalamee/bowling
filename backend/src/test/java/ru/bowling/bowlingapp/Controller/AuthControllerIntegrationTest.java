package ru.bowling.bowlingapp.Controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerIntegrationTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void refreshToken_validation() throws Exception {
		mockMvc.perform(post("/api/auth/refresh")
				.contentType(MediaType.APPLICATION_JSON)
				.content("{}"))
				.andExpect(status().isBadRequest());
	}

	// Password reset endpoints are currently disabled
	// @Test
	// void requestPasswordReset_validation() throws Exception {
	//		mockMvc.perform(post("/api/auth/reset-password/request")
	//				.contentType(MediaType.APPLICATION_JSON)
	//				.content("{\"phone\":\"invalid\"}"))
	//				.andExpect(status().isBadRequest());
	// }
} 