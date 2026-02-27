package ru.bowling.bowlingapp.Service.integration;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.integration.OneCSupplierSyncDTO;
import ru.bowling.bowlingapp.Entity.Supplier;
import ru.bowling.bowlingapp.Repository.SupplierRepository;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class OneCIntegrationService {

    private final SupplierRepository supplierRepository;

    public Supplier syncSupplier(OneCSupplierSyncDTO dto) {
        if (dto == null || dto.getInn() == null || dto.getInn().isBlank()) {
            throw new IllegalArgumentException("INN is required for 1C supplier sync");
        }

        String inn = dto.getInn().trim();
        Supplier supplier = supplierRepository.findFirstByInn(inn);
        if (supplier == null) {
            supplier = Supplier.builder()
                    .inn(inn)
                    .createdAt(LocalDateTime.now())
                    .build();
        }

        if (dto.getLegalName() != null) {
            supplier.setLegalName(dto.getLegalName());
        }
        if (dto.getContactPerson() != null) {
            supplier.setContactPerson(dto.getContactPerson());
        }
        if (dto.getContactPhone() != null) {
            supplier.setContactPhone(dto.getContactPhone());
        }
        if (dto.getContactEmail() != null) {
            supplier.setContactEmail(dto.getContactEmail());
        }
        if (dto.getVerified() != null) {
            supplier.setIsVerified(dto.getVerified());
        }

        supplier.setUpdatedAt(LocalDateTime.now());
        return supplierRepository.save(supplier);
    }
}
