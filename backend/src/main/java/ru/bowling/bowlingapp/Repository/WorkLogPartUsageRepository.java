package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.WorkLogPartUsage;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkLogPartUsageRepository extends JpaRepository<WorkLogPartUsage, Long> {

    // Поиск по журналу работ
    List<WorkLogPartUsage> findByWorkLogLogIdOrderByInstalledDate(Long workLogId);

    // Поиск по каталожному номеру
    List<WorkLogPartUsage> findByCatalogNumberOrderByInstalledDateDesc(String catalogNumber);

    // Поиск по источнику запчастей
    List<WorkLogPartUsage> findBySourcedFromOrderByInstalledDateDesc(String sourcedFrom);

    // Поиск по поставщику
    List<WorkLogPartUsage> findBySupplierIdOrderByInstalledDateDesc(Long supplierId);

    // Поиск по периоду установки
    List<WorkLogPartUsage> findByInstalledDateBetweenOrderByInstalledDateDesc(LocalDateTime startDate, LocalDateTime endDate);

    // Поиск по стоимости
    List<WorkLogPartUsage> findByTotalCostGreaterThanOrderByTotalCostDesc(Double cost);
    List<WorkLogPartUsage> findByTotalCostBetweenOrderByTotalCostDesc(Double minCost, Double maxCost);

    // Поиск по гарантии
    List<WorkLogPartUsage> findByWarrantyMonthsGreaterThanOrderByInstalledDateDesc(Integer months);
    List<WorkLogPartUsage> findByWarrantyMonthsIsNotNullOrderByInstalledDateDesc();

    // Поиск по номеру накладной
    List<WorkLogPartUsage> findByInvoiceNumberOrderByInstalledDateDesc(String invoiceNumber);

    // Поиск по создателю записи
    List<WorkLogPartUsage> findByCreatedByOrderByCreatedDateDesc(Long createdBy);

    // Комбинированные поиски
    List<WorkLogPartUsage> findByWorkLogLogIdAndCatalogNumber(Long workLogId, String catalogNumber);
    List<WorkLogPartUsage> findBySourcedFromAndSupplierId(String sourcedFrom, Long supplierId);

    // Статистические методы
    long countBySourcedFrom(String sourcedFrom);
    long countByWorkLogLogId(Long workLogId);
    long countBySupplierId(Long supplierId);
    long countByInstalledDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    // Существование записей
    boolean existsByWorkLogLogIdAndCatalogNumber(Long workLogId, String catalogNumber);
    boolean existsByInvoiceNumber(String invoiceNumber);
}
