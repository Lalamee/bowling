package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttestationApplicationDTO {
    private Long id;
    private Long userId;
    private Long mechanicProfileId;
    private Long clubId; // опционально для клубных механиков
    private AttestationDecisionStatus status;
    private String comment; // обязательный комментарий при отклонении
    private LocalDateTime submittedAt;
    private LocalDateTime updatedAt;
    private MechanicGrade requestedGrade;
}

