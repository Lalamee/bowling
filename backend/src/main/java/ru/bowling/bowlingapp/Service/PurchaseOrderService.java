package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.PurchaseOrderAcceptanceRequestDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderDetailDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderPartDTO;
import ru.bowling.bowlingapp.DTO.PurchaseOrderSummaryDTO;
import ru.bowling.bowlingapp.DTO.SupplierComplaintRequestDTO;
import ru.bowling.bowlingapp.DTO.SupplierComplaintStatusUpdateDTO;
import ru.bowling.bowlingapp.DTO.SupplierReviewDTO;
import ru.bowling.bowlingapp.DTO.SupplierReviewRequestDTO;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.PurchaseOrder;
import ru.bowling.bowlingapp.Entity.RequestPart;
import ru.bowling.bowlingapp.Entity.Supplier;
import ru.bowling.bowlingapp.Entity.SupplierReview;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Entity.enums.PurchaseOrderStatus;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Repository.PersonalWarehouseRepository;
import ru.bowling.bowlingapp.Repository.PurchaseOrderRepository;
import ru.bowling.bowlingapp.Repository.SupplierRepository;
import ru.bowling.bowlingapp.Repository.SupplierReviewRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PurchaseOrderService {

    private final PurchaseOrderRepository purchaseOrderRepository;
    private final SupplierReviewRepository supplierReviewRepository;
    private final ClubWarehouseService clubWarehouseService;
    private final SupplierRepository supplierRepository;
    private final WarehouseInventoryRepository warehouseInventoryRepository;
    private final PersonalWarehouseRepository personalWarehouseRepository;

    @Transactional(readOnly = true)
    public List<PurchaseOrderSummaryDTO> getOrders(Long clubId, boolean archived,
                                                   PurchaseOrderStatus status,
                                                   Boolean hasComplaint,
                                                   Boolean hasReview) {
        Collection<PurchaseOrderStatus> statusFilter;
        if (status != null) {
            statusFilter = List.of(status);
        } else if (archived) {
            statusFilter = EnumSet.of(PurchaseOrderStatus.COMPLETED,
                    PurchaseOrderStatus.PARTIALLY_COMPLETED,
                    PurchaseOrderStatus.REJECTED,
                    PurchaseOrderStatus.CANCELED);
        } else {
            statusFilter = EnumSet.of(PurchaseOrderStatus.PENDING,
                    PurchaseOrderStatus.CONFIRMED);
        }

        List<PurchaseOrder> orders = clubId != null
                ? purchaseOrderRepository.findByMaintenanceRequest_Club_ClubIdAndStatusIn(clubId, statusFilter)
                : purchaseOrderRepository.findByStatusIn(statusFilter);

        Map<Long, List<SupplierReview>> reviewsByOrder = loadReviewsGrouped(orders);

        return orders.stream()
                .map(order -> toSummary(order, reviewsByOrder.get(order.getOrderId())))
                .filter(dto -> filterByFlag(dto, hasComplaint, hasReview))
                .sorted(Comparator.comparing(PurchaseOrderSummaryDTO::getOrderDate,
                        Comparator.nullsLast(Comparator.naturalOrder())).reversed())
                .collect(Collectors.toList());
    }

    private boolean filterByFlag(PurchaseOrderSummaryDTO dto, Boolean hasComplaint, Boolean hasReview) {
        if (hasComplaint != null && hasComplaint && !dto.isHasComplaint()) {
            return false;
        }
        if (hasComplaint != null && !hasComplaint && dto.isHasComplaint()) {
            return false;
        }
        if (hasReview != null && hasReview && !dto.isHasReview()) {
            return false;
        }
        if (hasReview != null && !hasReview && dto.isHasReview()) {
            return false;
        }
        return true;
    }

    private Map<Long, List<SupplierReview>> loadReviewsGrouped(List<PurchaseOrder> orders) {
        if (orders == null || orders.isEmpty()) {
            return Map.of();
        }
        List<Long> orderIds = orders.stream()
                .map(PurchaseOrder::getOrderId)
                .filter(Objects::nonNull)
                .toList();
        if (orderIds.isEmpty()) {
            return Map.of();
        }
        return supplierReviewRepository.findByPurchaseOrder_OrderIdIn(orderIds).stream()
                .filter(review -> review.getPurchaseOrder() != null && review.getPurchaseOrder().getOrderId() != null)
                .collect(Collectors.groupingBy(review -> review.getPurchaseOrder().getOrderId()));
    }

    @Transactional(readOnly = true)
    public PurchaseOrderDetailDTO getOrderDetails(Long orderId) {
        PurchaseOrder order = purchaseOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Purchase order not found"));
        List<SupplierReview> reviews = supplierReviewRepository.findByPurchaseOrder_OrderId(orderId);
        return toDetail(order, reviews);
    }

    @Transactional
    public PurchaseOrderDetailDTO acceptOrder(Long orderId, PurchaseOrderAcceptanceRequestDTO request) {
        PurchaseOrder order = purchaseOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Purchase order not found"));

        Supplier resolvedSupplier = resolveSupplier(request, order.getSupplier());
        order.setSupplier(resolvedSupplier);

        List<PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO> payload = Optional.ofNullable(request.getParts())
                .filter(list -> !list.isEmpty())
                .orElseThrow(() -> new IllegalArgumentException("Acceptance payload is empty"));

        Map<Long, PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO> acceptanceByPart = payload.stream()
                .collect(Collectors.toMap(PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO::getPartId,
                        dto -> dto,
                        (left, right) -> right));

        LocalDateTime acceptanceMoment = LocalDateTime.now();
        int acceptedPositions = 0;
        int rejectedPositions = 0;

        List<RequestPart> parts = Optional.ofNullable(order.getOrderedParts()).orElseGet(List::of);
        for (RequestPart part : parts) {
            PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO acceptance = acceptanceByPart.get(part.getPartId());
            if (acceptance == null) {
                continue;
            }
            PartStatus targetStatus = acceptance.getStatus();
            if (targetStatus == null) {
                continue;
            }
            if (targetStatus != PartStatus.ACCEPTED
                    && targetStatus != PartStatus.PARTIALLY_ACCEPTED
                    && targetStatus != PartStatus.REJECTED) {
                continue;
            }
            int orderedQuantity = Optional.ofNullable(part.getQuantity()).orElse(0);
            int acceptedQuantity = Math.max(0, Math.min(orderedQuantity,
                    Optional.ofNullable(acceptance.getAcceptedQuantity()).orElse(orderedQuantity)));

            part.setStatus(targetStatus);
            part.setAcceptedQuantity(targetStatus == PartStatus.REJECTED ? 0 : acceptedQuantity);
            part.setAcceptanceComment(acceptance.getComment());
            part.setSupplierId(resolvedSupplier != null ? resolvedSupplier.getSupplierId() : part.getSupplierId());
            if (targetStatus == PartStatus.REJECTED) {
                part.setRejectionReason(acceptance.getComment());
                rejectedPositions++;
            } else {
                acceptedPositions++;
            }
            part.setAcceptanceDate(acceptanceMoment);
        }

        if (acceptedPositions == 0 && rejectedPositions == 0) {
            throw new IllegalArgumentException("Acceptance payload does not match order parts");
        }

        PurchaseOrderStatus resultingStatus;
        if (rejectedPositions > 0 && acceptedPositions == 0) {
            resultingStatus = PurchaseOrderStatus.REJECTED;
        } else if (acceptedPositions > 0 && rejectedPositions > 0) {
            resultingStatus = PurchaseOrderStatus.PARTIALLY_COMPLETED;
        } else {
            resultingStatus = PurchaseOrderStatus.COMPLETED;
        }

        order.setStatus(resultingStatus);
        order.setActualDeliveryDate(acceptanceMoment);
        purchaseOrderRepository.save(order);

        MaintenanceRequest requestEntity = order.getMaintenanceRequest();
        placeAcceptedParts(requestEntity, acceptanceByPart, parts);

        List<SupplierReview> reviews = supplierReviewRepository.findByPurchaseOrder_OrderId(orderId);
        return toDetail(order, reviews);
    }

    @Transactional
    public PurchaseOrderDetailDTO leaveReview(Long orderId, SupplierReviewRequestDTO reviewRequest, Long userId) {
        PurchaseOrder order = purchaseOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Purchase order not found"));
        Supplier supplier = order.getSupplier();
        MaintenanceRequest maintenanceRequest = order.getMaintenanceRequest();

        SupplierReview review = SupplierReview.builder()
                .purchaseOrder(order)
                .supplierId(supplier != null ? supplier.getSupplierId() : null)
                .clubId(maintenanceRequest != null && maintenanceRequest.getClub() != null
                        ? maintenanceRequest.getClub().getClubId() : null)
                .userId(userId)
                .rating(reviewRequest.getRating())
                .comment(reviewRequest.getComment())
                .reviewDate(LocalDateTime.now())
                .isComplaint(Boolean.FALSE)
                .complaintResolved(Boolean.FALSE)
                .build();
        supplierReviewRepository.save(review);
        recalculateSupplierRating(review.getSupplierId());
        List<SupplierReview> reviews = supplierReviewRepository.findByPurchaseOrder_OrderId(orderId);
        return toDetail(order, reviews);
    }

    @Transactional
    public PurchaseOrderDetailDTO submitComplaint(Long orderId,
                                                  SupplierComplaintRequestDTO complaintRequest,
                                                  Long userId) {
        PurchaseOrder order = purchaseOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Purchase order not found"));
        Supplier supplier = order.getSupplier();
        MaintenanceRequest maintenanceRequest = order.getMaintenanceRequest();

        SupplierReview complaint = SupplierReview.builder()
                .purchaseOrder(order)
                .supplierId(supplier != null ? supplier.getSupplierId() : null)
                .clubId(maintenanceRequest != null && maintenanceRequest.getClub() != null
                        ? maintenanceRequest.getClub().getClubId() : null)
                .userId(userId)
                .comment(complaintRequest.getDescription())
                .reviewDate(LocalDateTime.now())
                .isComplaint(Boolean.TRUE)
                .complaintResolved(Boolean.FALSE)
                .complaintStatus(complaintRequest.getStatus())
                .complaintTitle(complaintRequest.getTitle())
                .build();
        supplierReviewRepository.save(complaint);
        recalculateSupplierRating(complaint.getSupplierId());
        List<SupplierReview> reviews = supplierReviewRepository.findByPurchaseOrder_OrderId(orderId);
        return toDetail(order, reviews);
    }

    @Transactional
    public PurchaseOrderDetailDTO updateComplaintStatus(Long orderId, Long reviewId,
                                                        SupplierComplaintStatusUpdateDTO updateRequest) {
        PurchaseOrder order = purchaseOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Purchase order not found"));
        SupplierReview review = supplierReviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("Complaint review not found"));
        if (!Boolean.TRUE.equals(review.getIsComplaint())) {
            throw new IllegalArgumentException("Selected review is not a complaint");
        }
        review.setComplaintStatus(updateRequest.getStatus());
        if (updateRequest.getResolved() != null) {
            review.setComplaintResolved(updateRequest.getResolved());
        }
        if (updateRequest.getResolutionNotes() != null) {
            review.setResolutionNotes(updateRequest.getResolutionNotes());
        }
        supplierReviewRepository.save(review);
        recalculateSupplierRating(review.getSupplierId());
        List<SupplierReview> reviews = supplierReviewRepository.findByPurchaseOrder_OrderId(orderId);
        return toDetail(order, reviews);
    }

    private PurchaseOrderSummaryDTO toSummary(PurchaseOrder order, List<SupplierReview> reviews) {
        Supplier supplier = order.getSupplier();
        MaintenanceRequest maintenanceRequest = order.getMaintenanceRequest();
        BowlingClub club = maintenanceRequest != null ? maintenanceRequest.getClub() : null;
        List<RequestPart> parts = Optional.ofNullable(order.getOrderedParts()).orElseGet(List::of);
        int acceptedPositions = (int) parts.stream()
                .filter(part -> part.getAcceptedQuantity() != null && part.getAcceptedQuantity() > 0)
                .count();
        boolean hasReview = reviews != null && reviews.stream().anyMatch(review -> !Boolean.TRUE.equals(review.getIsComplaint()));
        boolean hasComplaint = reviews != null && reviews.stream().anyMatch(review -> Boolean.TRUE.equals(review.getIsComplaint()));

        return PurchaseOrderSummaryDTO.builder()
                .orderId(order.getOrderId())
                .requestId(maintenanceRequest != null ? maintenanceRequest.getRequestId() : null)
                .clubId(club != null ? club.getClubId() : null)
                .clubName(club != null ? club.getName() : null)
                .supplierName(supplier != null ? supplier.getLegalName() : null)
                .supplierInn(supplier != null ? supplier.getInn() : null)
                .status(order.getStatus())
                .orderDate(order.getOrderDate())
                .expectedDeliveryDate(order.getExpectedDeliveryDate())
                .actualDeliveryDate(order.getActualDeliveryDate())
                .totalPositions(parts.size())
                .acceptedPositions(acceptedPositions)
                .hasReview(hasReview)
                .hasComplaint(hasComplaint)
                .build();
    }

    private PurchaseOrderDetailDTO toDetail(PurchaseOrder order, List<SupplierReview> reviews) {
        Supplier supplier = order.getSupplier();
        MaintenanceRequest maintenanceRequest = order.getMaintenanceRequest();
        BowlingClub club = maintenanceRequest != null ? maintenanceRequest.getClub() : null;
        List<RequestPart> parts = Optional.ofNullable(order.getOrderedParts()).orElse(new ArrayList<>());
        List<SupplierReview> reviewList = Optional.ofNullable(reviews).orElseGet(List::of);
        List<SupplierReviewDTO> reviewDtos = reviewList.stream()
                .filter(review -> !Boolean.TRUE.equals(review.getIsComplaint()))
                .map(this::toReviewDto)
                .toList();
        List<SupplierReviewDTO> complaintDtos = reviewList.stream()
                .filter(review -> Boolean.TRUE.equals(review.getIsComplaint()))
                .map(this::toReviewDto)
                .toList();

        List<PurchaseOrderPartDTO> partDtos = parts.stream()
                .map(part -> PurchaseOrderPartDTO.builder()
                        .partId(part.getPartId())
                        .partName(part.getPartName())
                        .catalogNumber(part.getCatalogNumber())
                        .orderedQuantity(part.getQuantity())
                        .acceptedQuantity(part.getAcceptedQuantity())
                        .status(part.getStatus())
                        .rejectionReason(part.getRejectionReason())
                        .acceptanceComment(part.getAcceptanceComment())
                        .warehouseId(part.getWarehouseId())
                        .inventoryId(part.getInventoryId())
                        .inventoryLocation(part.getInventoryLocation())
                        .build())
                .collect(Collectors.toList());

        return PurchaseOrderDetailDTO.builder()
                .orderId(order.getOrderId())
                .requestId(maintenanceRequest != null ? maintenanceRequest.getRequestId() : null)
                .clubId(club != null ? club.getClubId() : null)
                .clubName(club != null ? club.getName() : null)
                .status(order.getStatus())
                .orderDate(order.getOrderDate())
                .expectedDeliveryDate(order.getExpectedDeliveryDate())
                .actualDeliveryDate(order.getActualDeliveryDate())
                .supplierName(supplier != null ? supplier.getLegalName() : null)
                .supplierInn(supplier != null ? supplier.getInn() : null)
                .supplierContact(supplier != null ? supplier.getContactPerson() : null)
                .supplierEmail(supplier != null ? supplier.getContactEmail() : null)
                .supplierPhone(supplier != null ? supplier.getContactPhone() : null)
                .parts(partDtos)
                .reviews(reviewDtos)
                .complaints(complaintDtos)
                .build();
    }

    private Supplier resolveSupplier(PurchaseOrderAcceptanceRequestDTO request, Supplier current) {
        String inn = Optional.ofNullable(request.getSupplierInn())
                .map(String::trim)
                .orElse(null);
        if (inn == null || inn.isBlank()) {
            return current;
        }
        Supplier supplier = supplierRepository.findFirstByInn(inn);
        if (supplier == null) {
            supplier = Supplier.builder()
                    .inn(inn)
                    .legalName(request.getSupplierName())
                    .contactPerson(request.getSupplierContactPerson())
                    .contactPhone(request.getSupplierPhone())
                    .contactEmail(request.getSupplierEmail())
                    .isVerified(Boolean.TRUE.equals(request.getSupplierVerified()))
                    .rating(current != null ? current.getRating() : null)
                    .createdAt(LocalDateTime.now())
                    .build();
        } else {
            if (request.getSupplierName() != null) {
                supplier.setLegalName(request.getSupplierName());
            }
            if (request.getSupplierContactPerson() != null) {
                supplier.setContactPerson(request.getSupplierContactPerson());
            }
            if (request.getSupplierPhone() != null) {
                supplier.setContactPhone(request.getSupplierPhone());
            }
            if (request.getSupplierEmail() != null) {
                supplier.setContactEmail(request.getSupplierEmail());
            }
            if (request.getSupplierVerified() != null) {
                supplier.setIsVerified(request.getSupplierVerified());
            }
        }
        supplier.setUpdatedAt(LocalDateTime.now());
        supplierRepository.save(supplier);
        return supplier;
    }

    private void placeAcceptedParts(MaintenanceRequest request,
                                    Map<Long, PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO> acceptanceByPart,
                                    List<RequestPart> parts) {
        if (parts == null || parts.isEmpty()) {
            return;
        }
        BowlingClub club = request != null ? request.getClub() : null;
        MechanicProfile mechanic = request != null ? request.getMechanic() : null;
        Integer personalWarehouseId = null;
        if (club == null && mechanic != null) {
            personalWarehouseId = ensurePersonalWarehouse(mechanic);
        }
        for (RequestPart part : parts) {
            if (part == null || part.getAcceptedQuantity() == null || part.getAcceptedQuantity() <= 0
                    || part.getCatalogId() == null) {
                continue;
            }
            PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO acceptance = acceptanceByPart.get(part.getPartId());
            Integer targetWarehouseId = club != null && club.getClubId() != null
                    ? Math.toIntExact(club.getClubId())
                    : personalWarehouseId;
            if (targetWarehouseId == null) {
                continue;
            }
            WarehouseInventory inventory = updateOrCreateInventory(targetWarehouseId,
                    part.getCatalogId().intValue(),
                    part.getAcceptedQuantity(),
                    acceptance);
            part.setWarehouseId(targetWarehouseId);
            if (inventory != null) {
                part.setInventoryId(inventory.getInventoryId());
                part.setInventoryLocation(buildInventoryLocation(inventory, acceptance));
                part.setIsAvailable(Boolean.TRUE);
            }
        }
    }

    private String buildInventoryLocation(WarehouseInventory inventory,
                                          PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO acceptance) {
        List<String> tokens = new ArrayList<>();
        if (acceptance != null && acceptance.getStorageLocation() != null) {
            tokens.add(acceptance.getStorageLocation());
        }
        if (inventory != null) {
            if (inventory.getShelfCode() != null) {
                tokens.add("shelf: " + inventory.getShelfCode());
            }
            if (inventory.getCellCode() != null) {
                tokens.add("cell: " + inventory.getCellCode());
            }
        }
        return String.join(", ", tokens);
    }

    private WarehouseInventory updateOrCreateInventory(Integer warehouseId,
                                                       Integer catalogId,
                                                       Integer quantity,
                                                       PurchaseOrderAcceptanceRequestDTO.PartAcceptanceDTO acceptance) {
        if (warehouseId == null || catalogId == null || quantity == null || quantity <= 0) {
            return null;
        }
        WarehouseInventory inventory = warehouseInventoryRepository
                .findFirstByWarehouseIdAndCatalogId(warehouseId, catalogId);
        if (inventory == null) {
            inventory = WarehouseInventory.builder()
                    .warehouseId(warehouseId)
                    .catalogId(catalogId)
                    .quantity(quantity)
                    .lastChecked(LocalDate.now())
                    .build();
        } else {
            int currentQty = Optional.ofNullable(inventory.getQuantity()).orElse(0);
            inventory.setQuantity(currentQty + quantity);
            if (inventory.getLastChecked() == null) {
                inventory.setLastChecked(LocalDate.now());
            }
        }
        if (acceptance != null) {
            if (acceptance.getStorageLocation() != null) {
                inventory.setLocationReference(acceptance.getStorageLocation());
            }
            if (acceptance.getShelfCode() != null) {
                inventory.setShelfCode(acceptance.getShelfCode());
            }
            if (acceptance.getCellCode() != null) {
                inventory.setCellCode(acceptance.getCellCode());
            }
            if (acceptance.getPlacementNotes() != null) {
                inventory.setNotes(acceptance.getPlacementNotes());
            }
        }
        return warehouseInventoryRepository.save(inventory);
    }

    private Integer ensurePersonalWarehouse(MechanicProfile mechanicProfile) {
        return personalWarehouseRepository.findByMechanicProfile_ProfileIdAndIsActiveTrue(mechanicProfile.getProfileId())
                .stream()
                .findFirst()
                .map(warehouse -> warehouse.getWarehouseId())
                .orElseGet(() -> {
                    var warehouse = ru.bowling.bowlingapp.Entity.PersonalWarehouse.builder()
                            .mechanicProfile(mechanicProfile)
                            .name("Личный zip-склад " + Optional.ofNullable(mechanicProfile.getFullName()).orElse("механика"))
                            .isActive(true)
                            .createdAt(LocalDateTime.now())
                            .updatedAt(LocalDateTime.now())
                            .build();
                    return personalWarehouseRepository.save(warehouse).getWarehouseId();
                });
    }

    private void recalculateSupplierRating(Long supplierId) {
        if (supplierId == null) {
            return;
        }
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElse(null);
        if (supplier == null) {
            return;
        }
        List<SupplierReview> reviews = supplierReviewRepository.findBySupplierId(supplierId);
        double average = reviews.stream()
                .map(SupplierReview::getRating)
                .filter(Objects::nonNull)
                .mapToInt(Integer::intValue)
                .average()
                .orElse(0.0);
        supplier.setRating(average > 0 ? average : null);
        supplier.setUpdatedAt(LocalDateTime.now());
        supplierRepository.save(supplier);
    }

    private SupplierReviewDTO toReviewDto(SupplierReview review) {
        return SupplierReviewDTO.builder()
                .reviewId(review.getReviewId())
                .rating(review.getRating())
                .comment(review.getComment())
                .complaint(Boolean.TRUE.equals(review.getIsComplaint()))
                .complaintStatus(review.getComplaintStatus())
                .complaintResolved(review.getComplaintResolved())
                .complaintTitle(review.getComplaintTitle())
                .resolutionNotes(review.getResolutionNotes())
                .createdAt(review.getReviewDate())
                .build();
    }
}
