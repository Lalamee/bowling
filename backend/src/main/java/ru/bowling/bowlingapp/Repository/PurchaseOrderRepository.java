package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.PurchaseOrder;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;

import java.util.Collection;
import java.util.List;

@Repository
public interface PurchaseOrderRepository extends JpaRepository<PurchaseOrder, Long> {
    List<PurchaseOrder> findByStatusIn(Collection<PurchaseOrderStatus> statuses);

    List<PurchaseOrder> findByMaintenanceRequest_Club_ClubIdAndStatusIn(Long clubId, Collection<PurchaseOrderStatus> statuses);
}
