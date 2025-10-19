package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.RequestPart;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;

import java.util.Collection;
import java.util.List;

@Repository
public interface RequestPartRepository extends JpaRepository<RequestPart, Long> {

	List<RequestPart> findByRequestRequestId(Long requestId);
	
	List<RequestPart> findByStatus(PartStatus status);
	
	List<RequestPart> findByCatalogNumber(String catalogNumber);
	
	List<RequestPart> findByRequestRequestIdAndStatus(Long requestId, PartStatus status);
	
	List<RequestPart> findByPartIdIn(Collection<Long> ids);
}
