package ru.bowling.bowlingapp.integration.onec.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OneCSyncStatusDto {
    private LocalDateTime startedAt;
    private LocalDateTime finishedAt;
    private Boolean success;
    private String trigger;
    private String message;
    private Integer imported;
    private Integer updated;
    private Integer skipped;
}
