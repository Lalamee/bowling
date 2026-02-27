package ru.bowling.bowlingapp.DTO.integration;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class OneCSupplierSyncDTO {
    String inn;
    String legalName;
    String contactPerson;
    String contactPhone;
    String contactEmail;
    Boolean verified;
}
