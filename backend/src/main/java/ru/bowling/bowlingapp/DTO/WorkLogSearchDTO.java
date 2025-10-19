package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class WorkLogSearchDTO {

    private Long clubId;
    private Integer laneNumber;
    private Long mechanicId;
    private Long equipmentId;
    private String status;
    private String workType;
    private Integer priority;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean completedOnly;
    private Boolean activeOnly;
    private String keyword; // для поиска по описанию
    private Boolean includeManualEdits;

    // Параметры пагинации
    @Builder.Default
    private Integer page = 0;
    @Builder.Default
    private Integer size = 20;
    @Builder.Default
    private String sortBy = "createdDate";
    @Builder.Default
    private String sortDirection = "DESC";
}
