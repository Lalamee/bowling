package ru.bowling.bowlingapp.DTO;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartsSearchDTO {

    private String searchQuery;
    private Long manufacturerId;
    private String catalogNumber;
    private Boolean isUnique;
    private String equipmentType;
    
    @Builder.Default
    private Integer page = 0;
    @Builder.Default
    private Integer size = 20;
    @Builder.Default
    private String sortBy = "catalogId";
    @Builder.Default
    private String sortDirection = "ASC";
}
