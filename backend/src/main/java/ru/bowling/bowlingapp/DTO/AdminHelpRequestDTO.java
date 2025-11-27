package ru.bowling.bowlingapp.DTO;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminHelpRequestDTO {
    private Long requestId;
    private Long partId;
    private Long mechanicProfileId;
    private Long clubId;
    private Integer laneNumber;
    private Boolean helpRequested;
    private String partStatus;
    private String managerNotes;
}
