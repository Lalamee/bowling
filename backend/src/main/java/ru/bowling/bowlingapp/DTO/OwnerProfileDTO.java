package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OwnerProfileDTO {
    @NotBlank
    private String inn;
    
    private String legalName;
    private String contactPerson;
    private String contactPhone;
    private String contactEmail;
}

