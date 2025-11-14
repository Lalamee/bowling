package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.SupplierReview;

import java.util.Collection;
import java.util.List;

@Repository
public interface SupplierReviewRepository extends JpaRepository<SupplierReview, Long> {
    List<SupplierReview> findByPurchaseOrder_OrderId(Long orderId);

    List<SupplierReview> findByPurchaseOrder_OrderIdIn(Collection<Long> orderIds);
}
