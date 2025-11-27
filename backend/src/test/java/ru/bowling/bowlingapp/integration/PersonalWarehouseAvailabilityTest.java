package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO.RequestedPartDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.MaintenanceRequestService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class PersonalWarehouseAvailabilityTest {

    @Autowired
    private MaintenanceRequestService maintenanceRequestService;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private PersonalWarehouseRepository personalWarehouseRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Autowired
    private RequestPartRepository requestPartRepository;

    @Test
    void personalWarehousePartBecomesAvailableInRequest() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Test Club")
                .createdAt(LocalDate.now())
                .build());

        User mechanicUser = User.builder()
                .phone("+70000000001")
                .passwordHash("pwd")
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();

        MechanicProfile mechanicProfile = MechanicProfile.builder()
                .user(mechanicUser)
                .fullName("Свободный Механик")
                .isDataVerified(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .clubs(List.of(club))
                .build();
        mechanicUser.setMechanicProfile(mechanicProfile);

        mechanicProfileRepository.save(mechanicProfile);

        PartsCatalog catalog = partsCatalogRepository.save(PartsCatalog.builder()
                .catalogNumber("PN-001")
                .officialNameRu("Втулка")
                .officialNameEn("Bushing")
                .commonName("Втулка")
                .categoryCode("NODE")
                .unit("pcs")
                .isUnique(false)
                .build());

        PersonalWarehouse warehouse = personalWarehouseRepository.save(PersonalWarehouse.builder()
                .mechanicProfile(mechanicProfile)
                .name("Личный zip-склад " + mechanicProfile.getFullName())
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build());

        warehouseInventoryRepository.save(WarehouseInventory.builder()
                .warehouseId(warehouse.getWarehouseId())
                .catalogId(catalog.getCatalogId().intValue())
                .quantity(3)
                .reservedQuantity(0)
                .cellCode("A1")
                .shelfCode("S1")
                .build());

        PartRequestDTO request = PartRequestDTO.builder()
                .clubId(club.getClubId())
                .mechanicId(mechanicProfile.getProfileId())
                .reason("Диагностика")
                .requestedParts(List.of(RequestedPartDTO.builder()
                        .catalogId(catalog.getCatalogId())
                        .catalogNumber(catalog.getCatalogNumber())
                        .partName("Втулка")
                        .quantity(1)
                        .build()))
                .build();

        var response = maintenanceRequestService.createPartRequest(request);

        assertThat(response.getStatus()).isEqualTo(MaintenanceRequestStatus.UNDER_REVIEW.name());

        List<RequestPart> parts = requestPartRepository.findAll();
        assertThat(parts).hasSize(1);
        RequestPart saved = parts.get(0);
        assertThat(saved.getIsAvailable()).isTrue();
        assertThat(saved.getStatus()).isEqualTo(PartStatus.APPROVED_FOR_ISSUE);
        assertThat(saved.getWarehouseId()).isEqualTo(warehouse.getWarehouseId());
        assertThat(saved.getInventoryId()).isNotNull();
        assertThat(saved.getInventoryLocation()).contains("A1").contains("S1");
    }
}
