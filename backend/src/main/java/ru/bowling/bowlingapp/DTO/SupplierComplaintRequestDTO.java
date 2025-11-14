package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
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
public class SupplierComplaintRequestDTO {
    @NotBlank
    private String title;

    @NotBlank
    private String description;

    @NotNull
    private SupplierComplaintStatus status;
}
