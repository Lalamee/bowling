package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;

@Data
@Builder
public class AdminAppealDTO {
    private String id;
    private String type;
    private String message;
    private Long requestId;
    private Long mechanicId;
    private Long clubId;
    private List<Long> partIds;
    private String payload;
    private OffsetDateTime createdAt;
}
