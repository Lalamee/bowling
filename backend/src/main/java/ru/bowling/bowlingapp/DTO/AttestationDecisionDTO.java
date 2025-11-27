package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.MechanicGrade;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttestationDecisionDTO {
    private AttestationDecisionStatus status;
    private String comment;
    private MechanicGrade approvedGrade;
}
