package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttestationApplicationDTO {
    private Long id;
    private Long userId;
    private Long mechanicProfileId;
    private Long clubId; // опционально для клубных механиков
    private String status; // NEW, IN_REVIEW, APPROVED, REJECTED — TODO: заменить на enum + таблицу
    private String comment; // обязательный комментарий при отклонении
    private LocalDateTime submittedAt;
    private LocalDateTime updatedAt;
    private String requestedGrade; // TODO: конкретизировать грейд после уточнения модели
}

