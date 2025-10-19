package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;

import java.util.List;

@Repository
public interface MaintenanceRequestRepository extends JpaRepository<MaintenanceRequest, Long> {

	List<MaintenanceRequest> findByStatus(MaintenanceRequestStatus status);
	
	List<MaintenanceRequest> findByStatusOrderByRequestDateDesc(MaintenanceRequestStatus status);
	
	List<MaintenanceRequest> findByClubClubId(Long clubId);
	
	List<MaintenanceRequest> findByMechanic_ProfileId(Long mechanicId);
	
	List<MaintenanceRequest> findByClubClubIdAndStatus(Long clubId, MaintenanceRequestStatus status);
	
	List<MaintenanceRequest> findAllByOrderByRequestDateDesc();
}
