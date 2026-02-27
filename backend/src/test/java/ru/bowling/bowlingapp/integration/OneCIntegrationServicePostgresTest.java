package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import ru.bowling.bowlingapp.DTO.integration.OneCSupplierSyncDTO;
import ru.bowling.bowlingapp.Entity.Supplier;
import ru.bowling.bowlingapp.Repository.SupplierRepository;
import ru.bowling.bowlingapp.Service.integration.OneCIntegrationService;
import ru.bowling.bowlingapp.integration.support.PostgresContainerBase;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class OneCIntegrationServicePostgresTest extends PostgresContainerBase {

    @Autowired
    private OneCIntegrationService oneCIntegrationService;

    @Autowired
    private SupplierRepository supplierRepository;

    @Test
    void shouldPersistSupplierFromOneCPayload() {
        OneCSupplierSyncDTO dto = OneCSupplierSyncDTO.builder()
                .inn("773301001")
                .legalName("ООО Поставщик 1С")
                .contactPerson("Интеграционный бот")
                .verified(true)
                .build();

        Supplier persisted = oneCIntegrationService.syncSupplier(dto);
        Supplier fromDb = supplierRepository.findById(persisted.getSupplierId()).orElseThrow();

        assertThat(fromDb.getInn()).isEqualTo("773301001");
        assertThat(fromDb.getLegalName()).isEqualTo("ООО Поставщик 1С");
        assertThat(fromDb.getIsVerified()).isTrue();
    }
}
