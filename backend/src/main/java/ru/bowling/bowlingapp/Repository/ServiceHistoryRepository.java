package ru.bowling.bowlingapp.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.ServiceHistory;
import ru.bowling.bowlingapp.Entity.enums.ServiceType;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ServiceHistoryRepository extends JpaRepository<ServiceHistory, Long> {

    List<ServiceHistory> findByClubClubIdOrderByServiceDateDesc(Long clubId);
    Page<ServiceHistory> findByClubClubId(Long clubId, Pageable pageable);

    List<ServiceHistory> findByEquipmentEquipmentIdOrderByServiceDateDesc(Long equipmentId);

    List<ServiceHistory> findByClubClubIdAndLaneNumberOrderByServiceDateDesc(Long clubId, Integer laneNumber);

    List<ServiceHistory> findByServiceTypeOrderByServiceDateDesc(ServiceType serviceType);

    List<ServiceHistory> findByPerformedByProfileIdOrderByServiceDateDesc(Long mechanicId);

    List<ServiceHistory> findBySupervisedByUserIdOrderByServiceDateDesc(Long supervisorId);

    List<ServiceHistory> findByServiceDateBetweenOrderByServiceDateDesc(LocalDateTime startDate, LocalDateTime endDate);
    List<ServiceHistory> findByServiceDateAfterOrderByServiceDateDesc(LocalDateTime startDate);
    List<ServiceHistory> findByServiceDateBeforeOrderByServiceDateDesc(LocalDateTime endDate);

    List<ServiceHistory> findByTotalCostGreaterThanOrderByServiceDateDesc(Double cost);
    List<ServiceHistory> findByTotalCostBetweenOrderByServiceDateDesc(Double minCost, Double maxCost);

    List<ServiceHistory> findByLaborHoursGreaterThanOrderByServiceDateDesc(Double hours);
    List<ServiceHistory> findByLaborHoursBetweenOrderByServiceDateDesc(Double minHours, Double maxHours);

    List<ServiceHistory> findByWarrantyUntilAfterOrderByWarrantyUntilAsc(LocalDateTime currentDate);
    List<ServiceHistory> findByWarrantyUntilIsNotNullOrderByWarrantyUntilAsc();

    List<ServiceHistory> findByNextServiceDueBeforeOrderByNextServiceDueAsc(LocalDateTime date);
    List<ServiceHistory> findByNextServiceDueIsNotNullOrderByNextServiceDueAsc();

    List<ServiceHistory> findByCreatedByOrderByServiceDateDesc(Long createdBy);

    List<ServiceHistory> findByClubClubIdAndServiceTypeOrderByServiceDateDesc(Long clubId, ServiceType serviceType);
    List<ServiceHistory> findByPerformedByProfileIdAndServiceTypeOrderByServiceDateDesc(Long mechanicId, ServiceType serviceType);
    List<ServiceHistory> findByEquipmentEquipmentIdAndServiceTypeOrderByServiceDateDesc(Long equipmentId, ServiceType serviceType);

    long countByServiceType(ServiceType serviceType);
    long countByPerformedByProfileId(Long mechanicId);
    long countByClubClubId(Long clubId);
    long countByServiceDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    long countByEquipmentEquipmentId(Long equipmentId);

    Page<ServiceHistory> findByServiceTypeOrderByServiceDateDesc(ServiceType serviceType, Pageable pageable);
    Page<ServiceHistory> findByPerformedByProfileIdOrderByServiceDateDesc(Long mechanicId, Pageable pageable);
    Page<ServiceHistory> findByServiceDateBetweenOrderByServiceDateDesc(LocalDateTime startDate, LocalDateTime endDate, Pageable pageable);
    Page<ServiceHistory> findAllByOrderByServiceDateDesc(Pageable pageable);

    boolean existsByEquipmentEquipmentId(Long equipmentId);
    boolean existsByPerformedByProfileId(Long mechanicId);
}
