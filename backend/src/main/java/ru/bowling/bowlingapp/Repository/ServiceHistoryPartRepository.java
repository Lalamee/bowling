package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.ServiceHistoryPart;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ServiceHistoryPartRepository extends JpaRepository<ServiceHistoryPart, Long> {

    List<ServiceHistoryPart> findByServiceHistoryServiceIdOrderByCreatedDate(Long serviceHistoryId);

    List<ServiceHistoryPart> findByCatalogNumberOrderByCreatedDateDesc(String catalogNumber);

    List<ServiceHistoryPart> findBySupplierIdOrderByCreatedDateDesc(Long supplierId);

    List<ServiceHistoryPart> findByTotalCostGreaterThanOrderByTotalCostDesc(Double cost);
    List<ServiceHistoryPart> findByTotalCostBetweenOrderByTotalCostDesc(Double minCost, Double maxCost);

    List<ServiceHistoryPart> findByWarrantyMonthsGreaterThanOrderByCreatedDateDesc(Integer months);
    List<ServiceHistoryPart> findByWarrantyMonthsIsNotNullOrderByCreatedDateDesc();

    List<ServiceHistoryPart> findByCreatedDateBetweenOrderByCreatedDateDesc(LocalDateTime startDate, LocalDateTime endDate);

    List<ServiceHistoryPart> findByServiceHistoryServiceIdAndCatalogNumber(Long serviceHistoryId, String catalogNumber);
    List<ServiceHistoryPart> findBySupplierIdAndWarrantyMonthsGreaterThan(Long supplierId, Integer months);

    long countByServiceHistoryServiceId(Long serviceHistoryId);
    long countBySupplierId(Long supplierId);
    long countByCreatedDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    boolean existsByServiceHistoryServiceIdAndCatalogNumber(Long serviceHistoryId, String catalogNumber);
}
