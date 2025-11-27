package ru.bowling.bowlingapp.integration;

import org.assertj.core.data.Offset;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.PurchaseOrderAcceptanceRequestDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderDetailDTO;
import ru.bowling.bowlingapp.DTO.SupplierComplaintRequestDTO;
import ru.bowling.bowlingapp.DTO.SupplierComplaintStatusUpdateDTO;
import ru.bowling.bowlingapp.DTO.SupplierReviewRequestDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Service.PurchaseOrderService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class PurchaseOrderAcceptanceFlowTest {

    @Autowired
    private PurchaseOrderService purchaseOrderService;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private MechanicProfileRepository mechanicProfileRepository;

    @Autowired
    private PartsCatalogRepository partsCatalogRepository;

    @Autowired
    private PurchaseOrderRepository purchaseOrderRepository;

    @Autowired
    private WarehouseInventoryRepository warehouseInventoryRepository;

    @Autowired
    private SupplierRepository supplierRepository;

    @Test
    void partialAcceptancePlacesStockAndUpdatesSupplierRating() {
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Rating Club")
                .createdAt(LocalDate.now())
                .build());

        User mechanicUser = User.builder()
                .phone("+79990000000")
                .passwordHash("pwd")
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(true)
                .build();

        MechanicProfile mechanicProfile = mechanicProfileRepository.save(MechanicProfile.builder()
                .user(mechanicUser)
                .fullName("Клубный механик")
                .clubs(List.of(club))
                .isDataVerified(true)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build());
        mechanicUser.setMechanicProfile(mechanicProfile);

        MaintenanceRequest maintenanceRequest = MaintenanceRequest.builder()
                .club(club)
                .mechanic(mechanicProfile)
                .status(MaintenanceRequestStatus.UNDER_REVIEW)
                .requestReason("Замена деталей")
                .requestDate(LocalDateTime.now())
                .build();

        PartsCatalog catalog = partsCatalogRepository.save(PartsCatalog.builder()
                .catalogNumber("PN-ACCEPT-1")
                .officialNameRu("Деталь 1")
                .categoryCode("NODE")
                .unit("pcs")
                .isUnique(false)
                .build());

        PartsCatalog catalog2 = partsCatalogRepository.save(PartsCatalog.builder()
                .catalogNumber("PN-ACCEPT-2")
                .officialNameRu("Деталь 2")
                .categoryCode("NODE")
                .unit("pcs")
                .isUnique(false)
                .build());

        Supplier supplier = supplierRepository.save(Supplier.builder()
                .inn("7712345678")
                .legalName("ООО Поставщик")
                .isVerified(false)
                .createdAt(LocalDateTime.now())
                .build());

        RequestPart part1 = RequestPart.builder()
                .catalogId(catalog.getCatalogId())
                .catalogNumber(catalog.getCatalogNumber())
                .partName("Деталь 1")
                .quantity(3)
                .status(PartStatus.ORDERED)
                .build();

        RequestPart part2 = RequestPart.builder()
                .catalogId(catalog2.getCatalogId())
                .catalogNumber(catalog2.getCatalogNumber())
                .partName("Деталь 2")
                .quantity(2)
                .status(PartStatus.ORDERED)
                .build();

        PurchaseOrder order = PurchaseOrder.builder()
                .supplier(supplier)
                .maintenanceRequest(maintenanceRequest)
                .orderedParts(List.of(part1, part2))
                .status(ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus.PENDING)
                .orderDate(LocalDateTime.now())
                .build();
        part1.setPurchaseOrder(order);
        part2.setPurchaseOrder(order);
        purchaseOrderRepository.save(order);

        PurchaseOrderAcceptanceRequestDTO acceptanceRequest = PurchaseOrderAcceptanceRequestDTO.builder()
                .supplierInn("7712345678")
                .supplierName("ООО Поставщик")
                .supplierContactPerson("Менеджер")
                .supplierPhone("+79990000001")
                .supplierEmail("manager@supplier.test")
                .parts(List.of(
                        PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO.builder()
                                .partId(part1.getPartId())
                                .status(PartStatus.PARTIALLY_ACCEPTED)
                                .acceptedQuantity(2)
                                .storageLocation("Стеллаж A")
                                .shelfCode("S-1")
                                .cellCode("C-1")
                                .build(),
                        PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO.builder()
                                .partId(part2.getPartId())
                                .status(PartStatus.REJECTED)
                                .acceptedQuantity(0)
                                .comment("брак")
                                .build()
                ))
                .build();

        PurchaseOrderDetailDTO accepted = purchaseOrderService.acceptOrder(order.getOrderId(), acceptanceRequest);

        assertThat(accepted.getStatus()).isEqualTo(ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus.PARTIALLY_COMPLETED);
        List<RequestPart> storedParts = purchaseOrderRepository.findById(order.getOrderId())
                .orElseThrow()
                .getOrderedParts();
        RequestPart storedAccepted = storedParts.stream()
                .filter(p -> p.getPartId().equals(part1.getPartId()))
                .findFirst().orElseThrow();
        assertThat(storedAccepted.getAcceptedQuantity()).isEqualTo(2);
        assertThat(storedAccepted.getWarehouseId()).isEqualTo(club.getClubId().intValue());

        WarehouseInventory inventory = warehouseInventoryRepository
                .findFirstByWarehouseIdAndCatalogId(club.getClubId().intValue(), catalog.getCatalogId().intValue());
        assertThat(inventory).isNotNull();
        assertThat(inventory.getQuantity()).isEqualTo(2);
        assertThat(inventory.getShelfCode()).isEqualTo("S-1");
        assertThat(inventory.getCellCode()).isEqualTo("C-1");

        purchaseOrderService.leaveReview(order.getOrderId(),
                SupplierReviewRequestDTO.builder().rating(5).comment("ok").build(), null);

        PurchaseOrderDetailDTO withComplaint = purchaseOrderService.submitComplaint(order.getOrderId(),
                SupplierComplaintRequestDTO.builder()
                        .status(SupplierComplaintStatus.SENT)
                        .title("Недопоставка")
                        .description("не хватило")
                        .build(),
                null);

        Long complaintId = withComplaint.getComplaints().get(0).getReviewId();
        purchaseOrderService.updateComplaintStatus(order.getOrderId(), complaintId,
                SupplierComplaintStatusUpdateDTO.builder()
                        .status(SupplierComplaintStatus.RESOLVED)
                        .resolved(true)
                        .resolutionNotes("Возврат средств")
                        .build());

        purchaseOrderService.leaveReview(order.getOrderId(),
                SupplierReviewRequestDTO.builder().rating(3).comment("средне").build(), null);

        Supplier ratedSupplier = supplierRepository.findFirstByInn("7712345678");
        assertThat(ratedSupplier.getRating()).isCloseTo(4.0, Offset.offset(0.01));
    }
}

