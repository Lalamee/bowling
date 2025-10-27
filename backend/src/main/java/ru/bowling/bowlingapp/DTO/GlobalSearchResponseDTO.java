package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GlobalSearchResponseDTO {

    @Builder.Default
    private List<PartDto> parts = List.of();

    @Builder.Default
    private List<MaintenanceRequestResult> maintenanceRequests = List.of();

    @Builder.Default
    private List<WorkLogResult> workLogs = List.of();

    @Builder.Default
    private List<ClubResult> clubs = List.of();

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MaintenanceRequestResult {
        private Long id;
        private String status;
        private String clubName;
        private Integer laneNumber;
        private String mechanicName;
        private LocalDateTime requestedAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkLogResult {
        private Long id;
        private String status;
        private String workType;
        private String clubName;
        private Integer laneNumber;
        private String mechanicName;
        private String problemDescription;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClubResult {
        private Long id;
        private String name;
        private String address;
        private Boolean active;
        private Boolean verified;
    }
}
