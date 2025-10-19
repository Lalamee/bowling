package ru.bowling.bowlingapp.Repository;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
class MaintenanceRequestRepositoryTest {

	@Autowired
	private MaintenanceRequestRepository repository;

	@Test
	void canPersistAndQueryByEnumStatus() {
		MaintenanceRequest req = MaintenanceRequest.builder()
				.requestDate(LocalDateTime.now())
				.status(MaintenanceRequestStatus.NEW)
				.build();
		repository.save(req);

		List<MaintenanceRequest> byEnum = repository.findByStatus(MaintenanceRequestStatus.NEW);
		assertThat(byEnum).isNotEmpty();
		assertThat(byEnum.get(0).getStatus()).isEqualTo(MaintenanceRequestStatus.NEW);

		List<MaintenanceRequest> ordered = repository.findByStatusOrderByRequestDateDesc(MaintenanceRequestStatus.NEW);
		assertThat(ordered).isNotEmpty();
	}
} 