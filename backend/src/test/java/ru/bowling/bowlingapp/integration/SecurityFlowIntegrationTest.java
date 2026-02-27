package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldDenyProtectedEndpointWithoutToken() throws Exception {
        mockMvc.perform(get("/api/parts/all"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "+79990000000", roles = {"ADMIN"})
    void shouldAllowProtectedEndpointForAuthenticatedUser() throws Exception {
        mockMvc.perform(get("/api/parts/all").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    @Test
    void shouldKeepAuthEndpointPublic() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
