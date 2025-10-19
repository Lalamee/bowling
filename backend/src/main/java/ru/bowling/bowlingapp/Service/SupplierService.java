package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.PurchaseOrder;
import ru.bowling.bowlingapp.Entity.RequestPart;
import ru.bowling.bowlingapp.Entity.Supplier;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;
import ru.bowling.bowlingapp.Repository.PurchaseOrderRepository;
import ru.bowling.bowlingapp.Repository.SupplierRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final PurchaseOrderRepository purchaseOrderRepository;
    private final SupplierRepository supplierRepository;

    @Transactional
    public PurchaseOrder createOrder(Long supplierId, MaintenanceRequest maintenanceRequest, List<RequestPart> parts) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found"));

        PurchaseOrder order = PurchaseOrder.builder()
                .supplier(supplier)
                .maintenanceRequest(maintenanceRequest)
                .orderedParts(parts)
                .status(PurchaseOrderStatus.PENDING)
                .orderDate(LocalDateTime.now())
                .build();

        PurchaseOrder savedOrder = purchaseOrderRepository.save(order);

        // Связываем запчасти с созданным заказом
        for (RequestPart part : parts) {
            part.setPurchaseOrder(savedOrder);
        }

        return savedOrder;
    }
}
