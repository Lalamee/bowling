package ru.bowling.bowlingapp.DTO;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApproveRejectRequestDTO {
        @Size(max = 1000)
        private String managerNotes;

        @Size(max = 1000)
        private String rejectionReason;

        @Valid
        private List<PartAvailabilityDTO> partsAvailability;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class PartAvailabilityDTO {
                @NotNull
                private Long partId;

                private Boolean available;
        }
}
