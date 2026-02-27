package ru.bowling.bowlingapp.Controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import ru.bowling.bowlingapp.Service.NotificationWebSocketPublisher;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(NotificationWebSocketController.class)
@AutoConfigureMockMvc(addFilters = false)
class NotificationWebSocketControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private NotificationWebSocketPublisher notificationWebSocketPublisher;

    @Test
    void broadcastFromRestPublishesMessage() throws Exception {
        mockMvc.perform(post("/api/public/ws/notifications/broadcast")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"message\":\"ping\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("sent"));

        verify(notificationWebSocketPublisher).publishTestBroadcast("ping");
    }
}
