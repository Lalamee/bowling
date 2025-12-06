package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.HelpRequestDTO;
import ru.bowling.bowlingapp.DTO.HelpResponseDTO;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO.RequestedPartDTO;
import ru.bowling.bowlingapp.DTO.NotificationEvent;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.MaintenanceRequestService;
import ru.bowling.bowlingapp.Service.NotificationService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class HelpRequestFlowIntegrationTest {

    @Autowired
    private MaintenanceRequestService maintenanceRequestService;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private RequestPartRepository requestPartRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private ManagerProfileRepository managerProfileRepository;

    @Test
    void mechanicHelpRequestSendsNotificationsAndCanBeConfirmed() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Help Club")
                .createdAt(LocalDate.now())
                .build());

        User mechanicUser = User.builder()
                .phone("+79999999999")
                .passwordHash("pwd")
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();

        MechanicProfile mechanicProfile = MechanicProfile.builder()
                .user(mechanicUser)
                .fullName("Механик Помощь")
                .isDataVerified(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .clubs(List.of(club))
                .build();
        mechanicUser.setMechanicProfile(mechanicProfile);
        mechanicProfileRepository.save(mechanicProfile);

        User managerUser = User.builder()
                .phone("+78888888888")
                .passwordHash("pwd")
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();
        ManagerProfile managerProfile = ManagerProfile.builder()
                .user(managerUser)
                .club(club)
                .fullName("Менеджер Клуба")
                .contactPhone(managerUser.getPhone())
                .isDataVerified(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        managerProfileRepository.save(managerProfile);

        PartRequestDTO partRequestDTO = new PartRequestDTO();
        partRequestDTO.setMechanicId(mechanicProfile.getProfileId());
        partRequestDTO.setClubId(club.getClubId());
        partRequestDTO.setLaneNumber(1);
        partRequestDTO.setReason("Сервис дорожки");

        RequestedPartDTO partDTO = new RequestedPartDTO();
        partDTO.setCatalogNumber("HELP-001");
        partDTO.setPartName("Датчик понижения");
        partDTO.setQuantity(1);
        partDTO.setHelpRequested(false);
        partRequestDTO.setRequestedParts(List.of(partDTO));

        MaintenanceRequestResponseDTO created = maintenanceRequestService.createPartRequest(partRequestDTO);

        HelpRequestDTO helpRequestDTO = new HelpRequestDTO();
        helpRequestDTO.setPartIds(created.getRequestedParts().stream().map(MaintenanceRequestResponseDTO.RequestPartResponseDTO::getPartId).toList());
        helpRequestDTO.setReason("Нет доступа к оборудованию");

        MaintenanceRequestResponseDTO afterHelp = maintenanceRequestService.requestHelp(created.getRequestId(), helpRequestDTO);

        List<RequestPart> partsAfterFlag = requestPartRepository.findByRequestRequestId(created.getRequestId());
        assertThat(partsAfterFlag).allMatch(RequestPart::getHelpRequested);
        assertThat(notificationService.getNotificationsForRole(RoleName.ADMIN))
                .extracting(NotificationEvent::getType)
                .contains(ru.bowling.bowlingapp.DTO.NotificationEventType.MECHANIC_HELP_REQUESTED);
        assertThat(notificationService.getNotificationsForRole(RoleName.HEAD_MECHANIC))
                .filteredOn(event -> event.getType() == ru.bowling.bowlingapp.DTO.NotificationEventType.MECHANIC_HELP_REQUESTED)
                .anyMatch(event -> event.getClubId() != null && event.getClubId().equals(club.getClubId()));

        HelpResponseDTO responseDTO = new HelpResponseDTO();
        responseDTO.setPartIds(helpRequestDTO.getPartIds());
        responseDTO.setDecision(HelpResponseDTO.Decision.APPROVED);
        responseDTO.setComment("Помощь организована");

        MaintenanceRequestResponseDTO resolved = maintenanceRequestService.resolveHelpRequest(created.getRequestId(), responseDTO);

        assertThat(resolved.getStatus()).isEqualTo(MaintenanceRequestStatus.UNDER_REVIEW.name());
        List<RequestPart> partsAfterDecision = requestPartRepository.findByRequestRequestId(created.getRequestId());
        assertThat(partsAfterDecision).allMatch(p -> Boolean.FALSE.equals(p.getHelpRequested()));
        assertThat(notificationService.getNotificationsForRole(RoleName.MECHANIC))
                .extracting(NotificationEvent::getType)
                .contains(ru.bowling.bowlingapp.DTO.NotificationEventType.MECHANIC_HELP_CONFIRMED);
        assertThat(notificationService.getNotificationsForRole(RoleName.CLUB_OWNER))
                .extracting(NotificationEvent::getMessage)
                .contains("Запрос помощи подтвержден");
    }
}
