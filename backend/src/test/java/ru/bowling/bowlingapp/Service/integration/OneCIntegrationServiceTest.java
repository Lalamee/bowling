package ru.bowling.bowlingapp.Service.integration;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import ru.bowling.bowlingapp.DTO.integration.OneCSupplierSyncDTO;
import ru.bowling.bowlingapp.Entity.Supplier;
import ru.bowling.bowlingapp.Repository.SupplierRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OneCIntegrationServiceTest {

    @Mock
    private SupplierRepository supplierRepository;

    @InjectMocks
    private OneCIntegrationService oneCIntegrationService;

    @Test
    void shouldCreateSupplierWhenInnNotFound() {
        OneCSupplierSyncDTO dto = OneCSupplierSyncDTO.builder()
                .inn("7712345678")
                .legalName("ООО Интеграция")
                .verified(true)
                .build();

        when(supplierRepository.findFirstByInn("7712345678")).thenReturn(null);
        when(supplierRepository.save(any(Supplier.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Supplier supplier = oneCIntegrationService.syncSupplier(dto);

        assertThat(supplier.getInn()).isEqualTo("7712345678");
        assertThat(supplier.getLegalName()).isEqualTo("ООО Интеграция");
        assertThat(supplier.getIsVerified()).isTrue();
        assertThat(supplier.getCreatedAt()).isNotNull();
    }

    @Test
    void shouldFailWhenInnMissing() {
        assertThatThrownBy(() -> oneCIntegrationService.syncSupplier(OneCSupplierSyncDTO.builder().build()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("INN is required");
    }
}
