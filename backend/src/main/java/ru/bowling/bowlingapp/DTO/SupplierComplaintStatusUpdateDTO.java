package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierComplaintStatusUpdateDTO {

    @NotNull
    private SupplierComplaintStatus status;

    private Boolean resolved;

    private String resolutionNotes;
}

