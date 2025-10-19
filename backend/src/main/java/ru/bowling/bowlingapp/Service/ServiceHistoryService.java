package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.ServiceType;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ServiceHistoryService {

    private final ServiceHistoryRepository serviceHistoryRepository;
    private final ServiceHistoryPartRepository serviceHistoryPartRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Transactional
    public ServiceHistory createServiceRecord(ServiceHistory serviceHistory, Long createdByUserId) {
        serviceHistory.setCreatedDate(LocalDateTime.now());
        serviceHistory.setCreatedBy(createdByUserId);

        if (serviceHistory.getServiceDate() == null) {
            serviceHistory.setServiceDate(LocalDateTime.now());
        }

        ServiceHistory savedRecord = serviceHistoryRepository.save(serviceHistory);
        
        notificationService.notifyServiceRecordCreated(savedRecord);
        
        log.info("Created service history record {} by user {}", savedRecord.getServiceId(), createdByUserId);
        return savedRecord;
    }

    @Transactional
    public ServiceHistory addPartsToServiceRecord(Long serviceHistoryId, List<ServiceHistoryPart> parts) {
        ServiceHistory serviceHistory = serviceHistoryRepository.findById(serviceHistoryId)
                .orElseThrow(() -> new IllegalArgumentException("Service history record not found"));

        for (ServiceHistoryPart part : parts) {
            part.setServiceHistory(serviceHistory);
            part.setCreatedDate(LocalDateTime.now());
            serviceHistoryPartRepository.save(part);
        }

        updateTotalCost(serviceHistory);

        log.info("Added {} parts to service record {}", parts.size(), serviceHistoryId);
        return serviceHistory;
    }

    @Transactional
    public ServiceHistory updateServiceRecord(Long serviceHistoryId, ServiceHistory updatedData) {
        ServiceHistory existingRecord = serviceHistoryRepository.findById(serviceHistoryId)
                .orElseThrow(() -> new IllegalArgumentException("Service history record not found"));

        existingRecord.setDescription(updatedData.getDescription());
        existingRecord.setPartsReplaced(updatedData.getPartsReplaced());
        existingRecord.setLaborHours(updatedData.getLaborHours());
        existingRecord.setServiceNotes(updatedData.getServiceNotes());
        existingRecord.setPerformanceMetrics(updatedData.getPerformanceMetrics());
        existingRecord.setPhotos(updatedData.getPhotos());
        existingRecord.setDocuments(updatedData.getDocuments());
        
        if (updatedData.getNextServiceDue() != null) {
            existingRecord.setNextServiceDue(updatedData.getNextServiceDue());
        }
        
        if (updatedData.getWarrantyUntil() != null) {
            existingRecord.setWarrantyUntil(updatedData.getWarrantyUntil());
        }

        updateTotalCost(existingRecord);

        ServiceHistory savedRecord = serviceHistoryRepository.save(existingRecord);
        
        log.info("Updated service history record {}", serviceHistoryId);
        return savedRecord;
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByEquipment(Long equipmentId) {
        return serviceHistoryRepository.findByEquipmentEquipmentIdOrderByServiceDateDesc(equipmentId);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByClub(Long clubId) {
        return serviceHistoryRepository.findByClubClubIdOrderByServiceDateDesc(clubId);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByLane(Long clubId, Integer laneNumber) {
        return serviceHistoryRepository.findByClubClubIdAndLaneNumberOrderByServiceDateDesc(clubId, laneNumber);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByMechanic(Long mechanicId) {
        return serviceHistoryRepository.findByPerformedByProfileIdOrderByServiceDateDesc(mechanicId);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByType(ServiceType serviceType) {
        return serviceHistoryRepository.findByServiceTypeOrderByServiceDateDesc(serviceType);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getServiceHistoryByPeriod(LocalDateTime startDate, LocalDateTime endDate) {
        return serviceHistoryRepository.findByServiceDateBetweenOrderByServiceDateDesc(startDate, endDate);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getRecordsWithActiveWarranty() {
        return serviceHistoryRepository.findByWarrantyUntilAfterOrderByWarrantyUntilAsc(LocalDateTime.now());
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getRecordsDueForService() {
        return serviceHistoryRepository.findByNextServiceDueBeforeOrderByNextServiceDueAsc(LocalDateTime.now());
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getUpcomingServiceDue(int daysAhead) {
        LocalDateTime futureDate = LocalDateTime.now().plusDays(daysAhead);
        return serviceHistoryRepository.findByNextServiceDueBeforeOrderByNextServiceDueAsc(futureDate);
    }

    @Transactional(readOnly = true)
    public Page<ServiceHistory> getServiceHistoryPageable(Pageable pageable) {
        return serviceHistoryRepository.findAllByOrderByServiceDateDesc(pageable);
    }

    @Transactional(readOnly = true)
    public Page<ServiceHistory> getServiceHistoryByClubPageable(Long clubId, Pageable pageable) {
        return serviceHistoryRepository.findByClubClubId(clubId, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ServiceHistory> getServiceHistoryByMechanicPageable(Long mechanicId, Pageable pageable) {
        return serviceHistoryRepository.findByPerformedByProfileIdOrderByServiceDateDesc(mechanicId, pageable);
    }

    @Transactional(readOnly = true)
    public Optional<ServiceHistory> getServiceHistoryById(Long serviceHistoryId) {
        return serviceHistoryRepository.findById(serviceHistoryId);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistoryPart> getPartsUsedInService(Long serviceHistoryId) {
        return serviceHistoryPartRepository.findByServiceHistoryServiceIdOrderByCreatedDate(serviceHistoryId);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getExpensiveServices(Double minCost) {
        return serviceHistoryRepository.findByTotalCostGreaterThanOrderByServiceDateDesc(minCost);
    }

    @Transactional(readOnly = true)
    public List<ServiceHistory> getTimeConsumingServices(Double minHours) {
        return serviceHistoryRepository.findByLaborHoursGreaterThanOrderByServiceDateDesc(minHours);
    }

    @Transactional(readOnly = true)
    public long getServiceCountByType(ServiceType serviceType) {
        return serviceHistoryRepository.countByServiceType(serviceType);
    }

    @Transactional(readOnly = true)
    public long getServiceCountByMechanic(Long mechanicId) {
        return serviceHistoryRepository.countByPerformedByProfileId(mechanicId);
    }

    @Transactional(readOnly = true)
    public long getServiceCountByClub(Long clubId) {
        return serviceHistoryRepository.countByClubClubId(clubId);
    }

    @Transactional(readOnly = true)
    public long getServiceCountByEquipment(Long equipmentId) {
        return serviceHistoryRepository.countByEquipmentEquipmentId(equipmentId);
    }

    @Transactional(readOnly = true)
    public boolean hasServiceHistory(Long equipmentId) {
        return serviceHistoryRepository.existsByEquipmentEquipmentId(equipmentId);
    }

    private void updateTotalCost(ServiceHistory serviceHistory) {
        List<ServiceHistoryPart> parts = serviceHistoryPartRepository
                .findByServiceHistoryServiceIdOrderByCreatedDate(serviceHistory.getServiceId());
        
        Double partsCost = parts.stream()
                .mapToDouble(part -> part.getTotalCost() != null ? part.getTotalCost() : 0.0)
                .sum();

        Double laborCost = (serviceHistory.getLaborHours() != null && serviceHistory.getLaborHours() > 0) 
                ? serviceHistory.getLaborHours() * 1000.0 // Предполагаемая стоимость часа работы
                : 0.0;

        serviceHistory.setTotalCost(partsCost + laborCost);
        serviceHistoryRepository.save(serviceHistory);
        
        log.debug("Updated total cost for service {} to {}", serviceHistory.getServiceId(), serviceHistory.getTotalCost());
    }
}
