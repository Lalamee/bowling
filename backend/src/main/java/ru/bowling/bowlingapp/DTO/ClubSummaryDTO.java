package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClubSummaryDTO {
    private Long id;
    private String name;
    private String address;
    private Integer lanesCount;
    private String contactPhone;
    private String contactEmail;
}
