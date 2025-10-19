package ru.bowling.bowlingapp.DTO;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import ru.bowling.bowlingapp.Entity.enums.AvailabilityStatus;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartsCatalogResponseDTO {

	private Long catalogId;
	private Long manufacturerId;
	private String manufacturerName;
	private String catalogNumber;
	private String officialNameEn;
	private String officialNameRu;
	private String commonName;
	private String description;
	private Integer normalServiceLife;
	private String unit;
	private Boolean isUnique;
	private Integer availableQuantity;
	private AvailabilityStatus availabilityStatus;
}
