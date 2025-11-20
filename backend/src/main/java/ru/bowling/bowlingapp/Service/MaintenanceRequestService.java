package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.ApproveRejectRequestDTO;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.DTO.StockIssueDecisionDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.MaintenanceRequestRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.ManagerProfileRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.RequestPartRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MaintenanceRequestService {

        private final MaintenanceRequestRepository maintenanceRequestRepository;
        private final RequestPartRepository requestPartRepository;
        private final MechanicProfileRepository mechanicProfileRepository;
        private final ManagerProfileRepository managerProfileRepository;
        private final PartsCatalogRepository partsCatalogRepository;
        private final BowlingClubRepository bowlingClubRepository;
        private final ClubStaffRepository clubStaffRepository;
        private final UserRepository userRepository;
        private final InventoryService inventoryService;
        private final SupplierService supplierService;
        private final NotificationService notificationService;
        private final WarehouseInventoryRepository warehouseInventoryRepository;

        @Transactional
        public MaintenanceRequestResponseDTO createPartRequest(PartRequestDTO requestDTO) {
                Optional<MechanicProfile> mechanic = mechanicProfileRepository.findById(requestDTO.getMechanicId());
                if (mechanic.isEmpty()) {
                        throw new IllegalArgumentException("Mechanic not found");
                }

                if (requestDTO.getClubId() == null) {
                        throw new IllegalArgumentException("Club is required");
                }

                BowlingClub club = bowlingClubRepository.findById(requestDTO.getClubId())
                                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

                MechanicProfile mechanicProfile = mechanic.get();
                if (!mechanicWorksInClub(mechanicProfile, club.getClubId())) {
                        throw new IllegalArgumentException("Mechanic is not assigned to the specified club");
                }

                validateRequestedParts(requestDTO.getRequestedParts());

                String reason = normalizeValue(requestDTO.getReason());
                if (reason == null || reason.isBlank()) {
                        throw new IllegalArgumentException("Причина закупки/выдачи запчасти обязательна");
                }

                // Для закупки дорожка по замечанию не обязательна. Для выдачи со склада придётся уточнить, есть ли отдельный флаг типа заявки.
                if (requestDTO.getLaneNumber() != null && requestDTO.getLaneNumber() <= 0) {
                        throw new IllegalArgumentException("Lane number must be > 0 when provided");
                }

                MaintenanceRequest request = MaintenanceRequest.builder()
                                .club(club)
                                .laneNumber(requestDTO.getLaneNumber())
                                .mechanic(mechanicProfile)
                                .requestDate(LocalDateTime.now())
                                .status(MaintenanceRequestStatus.UNDER_REVIEW)
                                .managerNotes(requestDTO.getManagerNotes())
                                .verificationStatus("NOT_VERIFIED")
                                .requestReason(reason)
                                .build();

                MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

                List<RequestPart> requestParts = requestDTO.getRequestedParts().stream()
                                .map(partDTO -> requestPartRepository.save(buildRequestPart(savedRequest, partDTO)))
                                .collect(Collectors.toList());

                notifyClubTeamAboutRequest(savedRequest);

                return convertToResponseDTO(savedRequest, requestParts);
        }

        @Transactional(readOnly = true)
        public List<MaintenanceRequestResponseDTO> getAllRequests() {
                List<MaintenanceRequest> requests = maintenanceRequestRepository.findAllByOrderByRequestDateDesc();
                return requests.stream()
                                .map(request -> {
                                        List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                                        return convertToResponseDTO(request, parts);
                                })
                                .collect(Collectors.toList());
        }

        @Transactional(readOnly = true)
        public MaintenanceRequestResponseDTO getRequestById(Long requestId) {
                MaintenanceRequest request = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
                return convertToResponseDTO(request, parts);
        }

        @Transactional(readOnly = true)
        public List<MaintenanceRequestResponseDTO> getRequestsByStatus(String status) {
                MaintenanceRequestStatus st;
                try {
                        st = MaintenanceRequestStatus.valueOf(status);
		} catch (IllegalArgumentException ex) {
			throw new IllegalArgumentException("Unknown status: " + status);
		}
		List<MaintenanceRequest> requests = maintenanceRequestRepository.findByStatusOrderByRequestDateDesc(st);
		return requests.stream()
				.map(request -> {
					List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
					return convertToResponseDTO(request, parts);
				})
				.collect(Collectors.toList());
	}

        @Transactional(readOnly = true)
        public List<MaintenanceRequestResponseDTO> getRequestsByMechanic(Long mechanicId) {
                List<MaintenanceRequest> requests = maintenanceRequestRepository.findByMechanic_ProfileId(mechanicId);
                return requests.stream()
                                .map(request -> {
                                        List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                                        return convertToResponseDTO(request, parts);
                                })
                                .collect(Collectors.toList());
        }

        @Transactional(readOnly = true)
        public List<MaintenanceRequestResponseDTO> getRequestsByClub(Long clubId, String requestedByLogin) {
                if (clubId == null) {
                        throw new IllegalArgumentException("Club is required");
                }

                BowlingClub club = bowlingClubRepository.findById(clubId)
                                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

                if (requestedByLogin != null && !requestedByLogin.isBlank()) {
                        User requester = findUserByLogin(requestedByLogin);
                        if (requester == null) {
                                throw new IllegalArgumentException("User not found");
                        }
                        if (!userHasAccessToClub(requester, club)) {
                                throw new IllegalArgumentException("You do not have access to this club");
                        }
                }

                List<MaintenanceRequest> requests = maintenanceRequestRepository.findByClubClubIdOrderByRequestDateDesc(clubId);
                return requests.stream()
                                .map(request -> {
                                        List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                                        return convertToResponseDTO(request, parts);
                                })
                                .collect(Collectors.toList());
        }

        @Transactional
        public MaintenanceRequestResponseDTO addPartsToRequest(Long requestId, List<PartRequestDTO.RequestedPartDTO> partsToAdd) {
                if (partsToAdd == null || partsToAdd.isEmpty()) {
                        throw new IllegalArgumentException("At least one part must be provided");
                }

                MaintenanceRequest request = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));

                if (request.getStatus() == MaintenanceRequestStatus.CLOSED
                                || request.getStatus() == MaintenanceRequestStatus.UNREPAIRABLE
                                || request.getStatus() == MaintenanceRequestStatus.DONE) {
                        throw new IllegalStateException("Parts cannot be added to closed or completed requests");
                }

                validateRequestedParts(partsToAdd);

                for (PartRequestDTO.RequestedPartDTO partDTO : partsToAdd) {
                        RequestPart requestPart = buildRequestPart(request, partDTO);
                        requestPartRepository.save(requestPart);
                }

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                return convertToResponseDTO(request, parts);
        }

        private boolean mechanicWorksInClub(MechanicProfile mechanicProfile, Long clubId) {
                if (mechanicProfile == null || clubId == null) {
                        return false;
                }

                User mechanicUser = mechanicProfile.getUser();
                if (mechanicUser != null && mechanicUser.getUserId() != null
                                && clubStaffRepository.existsByClubClubIdAndUserUserIdAndIsActiveTrue(clubId, mechanicUser.getUserId())) {
                        return true;
                }

                return Optional.ofNullable(mechanicProfile.getClubs())
                                .orElse(List.of())
                                .stream()
                                .map(BowlingClub::getClubId)
                                .filter(Objects::nonNull)
                                .anyMatch(id -> id.equals(clubId));
        }

        private boolean userHasAccessToClub(User user, BowlingClub club) {
                if (user == null || club == null) {
                        return false;
                }

                if (isGlobalAdministrator(user)) {
                        return true;
                }

                OwnerProfile owner = club.getOwner();
                if (owner != null && owner.getUser() != null && Objects.equals(owner.getUser().getUserId(), user.getUserId())) {
                        return true;
                }

                if (clubStaffRepository.existsByClubAndUserAndIsActiveTrue(club, user)) {
                        return true;
                }

                if (hasActiveManagerAccess(user, club)) {
                        return true;
                }

                AdministratorProfile administratorProfile = user.getAdministratorProfile();
                if (administratorProfile != null && administratorProfile.getClub() != null
                                && Objects.equals(administratorProfile.getClub().getClubId(), club.getClubId())) {
                        return true;
                }

                MechanicProfile mechanicProfile = user.getMechanicProfile();
                if (mechanicProfile != null && mechanicWorksInClub(mechanicProfile, club.getClubId())) {
                        return true;
                }

                return false;
        }

        private boolean isGlobalAdministrator(User user) {
                if (user == null || user.getRole() == null || user.getRole().getName() == null) {
                        return false;
                }
                String roleName = user.getRole().getName().toUpperCase(Locale.ROOT);
                return roleName.contains("ADMIN");
        }

        private boolean hasActiveManagerAccess(User user, BowlingClub club) {
                if (user == null || club == null) {
                        return false;
                }

                ManagerProfile managerProfile = user.getManagerProfile();
                if (managerProfile == null || managerProfile.getClub() == null) {
                        return false;
                }

                if (!Boolean.TRUE.equals(user.getIsVerified())) {
                        return false;
                }

                if (!Boolean.TRUE.equals(managerProfile.getIsDataVerified())) {
                        return false;
                }

                if (!Objects.equals(managerProfile.getClub().getClubId(), club.getClubId())) {
                        return false;
                }

                return clubStaffRepository.existsByClubAndUserAndIsActiveTrue(club, user);
        }

        private User findUserByLogin(String login) {
                if (login == null || login.isBlank()) {
                        return null;
                }
                Optional<User> direct = userRepository.findByPhone(login);
                if (direct.isPresent()) {
                        return direct.get();
                }
                String normalized = normalizePhone(login);
                if (normalized != null) {
                        return userRepository.findByPhone(normalized).orElse(null);
                }
                return null;
        }

        private String normalizePhone(String rawPhone) {
                if (rawPhone == null) {
                        return null;
                }
                String digits = rawPhone.replaceAll("\\D", "");
                if (digits.length() == 11 && digits.startsWith("8")) {
                        digits = "7" + digits.substring(1);
                }
                if (digits.length() == 10) {
                        digits = "7" + digits;
                }
                if (digits.length() != 11 || !digits.startsWith("7")) {
                        return null;
                }
                return "+" + digits.charAt(0) + digits.substring(1);
        }

        private void validateRequestedParts(List<PartRequestDTO.RequestedPartDTO> parts) {
                if (parts == null || parts.isEmpty()) {
                        throw new IllegalArgumentException("At least one part must be provided");
                }

                for (PartRequestDTO.RequestedPartDTO partDTO : parts) {
                        if (partDTO == null) {
                                throw new IllegalArgumentException("Part data is required");
                        }

                        String partName = normalizeValue(partDTO.getPartName());
                        if (partName == null) {
                                throw new IllegalArgumentException("Название запчасти обязательно для заполнения");
                        }

                        Integer quantity = partDTO.getQuantity();
                        if (quantity == null || quantity <= 0) {
                                throw new IllegalArgumentException("Количество для детали '" + safePartName(partDTO) + "' должно быть больше нуля");
                        }
                }
        }

        private RequestPart buildRequestPart(MaintenanceRequest request, PartRequestDTO.RequestedPartDTO partDTO) {
                if (request == null) {
                        throw new IllegalArgumentException("Request is required");
                }
                if (partDTO == null) {
                        throw new IllegalArgumentException("Part data is required");
                }

                String catalogNumber = normalizeValue(partDTO.getCatalogNumber());
                String partName = normalizeValue(partDTO.getPartName());
                String location = normalizeValue(partDTO.getLocation());
                Long catalogId = partDTO.getCatalogId();
                Long inventoryId = partDTO.getInventoryId();
                Integer warehouseId = partDTO.getWarehouseId();

                if (partName == null) {
                        partName = catalogNumber != null ? catalogNumber : "Неизвестная запчасть";
                }

                return RequestPart.builder()
                                .request(request)
                                .catalogNumber(catalogNumber)
                                .partName(partName)
                                .quantity(partDTO.getQuantity())
                                .status(PartStatus.APPROVAL_PENDING)
                                .inventoryId(inventoryId)
                                .catalogId(catalogId)
                                .warehouseId(warehouseId)
                                .inventoryLocation(location)
                                // сохраняем признак запроса помощи по детали
                                .helpRequested(Boolean.TRUE.equals(partDTO.getHelpRequested()))
                                .build();
        }

        private String normalizeValue(String value) {
                if (value == null) {
                        return null;
                }
                String trimmed = value.trim();
                return trimmed.isEmpty() ? null : trimmed;
        }

        private String safePartName(PartRequestDTO.RequestedPartDTO partDTO) {
                if (partDTO == null) {
                        return "неизвестная запчасть";
                }
                String name = normalizeValue(partDTO.getPartName());
                if (name != null) {
                        return name;
                }
                String catalogNumber = normalizeValue(partDTO.getCatalogNumber());
                if (catalogNumber != null) {
                        return catalogNumber;
                }
                if (partDTO.getCatalogId() != null) {
                        return partDTO.getCatalogId().toString();
                }
                if (partDTO.getInventoryId() != null) {
                        return partDTO.getInventoryId().toString();
                }
                return "неизвестная запчасть";
        }

        private void synchronizeManualWarehouse(RequestPart part, int approvedQty) {
                if (part == null || approvedQty <= 0) {
                        return;
                }
                Long inventoryId = part.getInventoryId();
                if (inventoryId == null) {
                        return;
                }
                WarehouseInventory inventory = warehouseInventoryRepository.findById(inventoryId)
                        .orElseThrow(() -> new IllegalStateException(
                                "Складская позиция не найдена для inventoryId=" + inventoryId));
                int currentQty = Optional.ofNullable(inventory.getQuantity()).orElse(0);
                if (currentQty < approvedQty) {
                        throw new IllegalStateException("Недостаточно остатков на складе для inventoryId=" + inventoryId);
                }
                inventory.setQuantity(currentQty - approvedQty);
                Integer reserved = Optional.ofNullable(inventory.getReservedQuantity()).orElse(0);
                inventory.setReservedQuantity(reserved + approvedQty);
                warehouseInventoryRepository.save(inventory);
        }

        @Transactional
        public MaintenanceRequestResponseDTO approveRequest(Long requestId,
                                                           String managerNotes,
                                                           List<ApproveRejectRequestDTO.PartAvailabilityDTO> availabilityUpdates) {
                Optional<MaintenanceRequest> requestOpt = maintenanceRequestRepository.findById(requestId);
                if (requestOpt.isEmpty()) {
                        throw new IllegalArgumentException("Request not found");
                }

                MaintenanceRequest request = requestOpt.get();
                request.setStatus(MaintenanceRequestStatus.APPROVED);
                request.setManagerNotes(managerNotes);
                request.setManagerDecisionDate(LocalDateTime.now());

                MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
                Map<Long, Boolean> availabilityByPart = Optional.ofNullable(availabilityUpdates)
                                .orElse(List.of())
                                .stream()
                                .filter(Objects::nonNull)
                                .collect(Collectors.toMap(
                                                ApproveRejectRequestDTO.PartAvailabilityDTO::getPartId,
                                                ApproveRejectRequestDTO.PartAvailabilityDTO::getAvailable,
                                                (first, second) -> second,
                                                LinkedHashMap::new));

                parts.forEach(part -> {
                        part.setStatus(null);
                        if (!availabilityByPart.isEmpty()) {
                                Boolean available = availabilityByPart.get(part.getPartId());
                                if (available != null) {
                                        part.setIsAvailable(available);
                                }
                        }
                        requestPartRepository.save(part);
                });

                return convertToResponseDTO(savedRequest, parts);
        }

        @Transactional
        public MaintenanceRequestResponseDTO issueFromStock(Long requestId, StockIssueDecisionDTO decisionDTO) {
                if (decisionDTO == null || decisionDTO.getPartDecisions() == null
                                || decisionDTO.getPartDecisions().isEmpty()) {
                        throw new IllegalArgumentException("Не переданы решения по позициям");
                }

                MaintenanceRequest request = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
                Map<Long, RequestPart> partsById = parts.stream()
                                .filter(Objects::nonNull)
                                .collect(Collectors.toMap(RequestPart::getPartId, p -> p));

                boolean anyApproved = false;
                boolean anyPartial = false;
                boolean anyRejected = false;

                for (StockIssueDecisionDTO.PartDecisionDTO decision : decisionDTO.getPartDecisions()) {
                        if (decision == null) {
                                continue;
                        }

                        RequestPart part = partsById.get(decision.getPartId());
                        if (part == null) {
                                throw new IllegalArgumentException("Позиция не найдена в заявке");
                        }

                        int requestedQty = Optional.ofNullable(part.getQuantity()).orElse(0);
                        int approvedQty = Optional.ofNullable(decision.getApprovedQuantity()).orElse(0);

                        if (approvedQty < 0) {
                                throw new IllegalArgumentException("Количество не может быть отрицательным");
                        }
                        if (approvedQty > requestedQty) {
                                throw new IllegalArgumentException("Согласованное количество превышает запрошенное");
                        }

                        part.setAcceptedQuantity(approvedQty);
                        part.setAcceptanceComment(decision.getManagerComment());
                        part.setAcceptanceDate(LocalDateTime.now());

                        if (approvedQty == 0) {
                                part.setStatus(PartStatus.REJECTED);
                                anyRejected = true;
                        } else if (approvedQty < requestedQty) {
                                part.setStatus(PartStatus.PARTIALLY_ACCEPTED);
                                anyPartial = true;
                                anyApproved = true;
                        } else {
                                part.setStatus(PartStatus.APPROVED_FOR_ISSUE);
                                anyApproved = true;
                        }

                        if (approvedQty > 0) {
                                if (part.getCatalogId() != null) {
                                        try {
                                                ReservationRequestDto reservationRequest = new ReservationRequestDto(
                                                                part.getCatalogId(), approvedQty, requestId);
                                                inventoryService.reservePart(reservationRequest);
                                        } catch (RuntimeException ex) {
                                                throw new IllegalStateException(
                                                                "Недостаточно остатков для выдачи запчасти '" + part.getPartName() + "'",
                                                                ex);
                                        }
                                } else {
                                        synchronizeManualWarehouse(part, approvedQty);
                                }
                                part.setIssueDate(LocalDateTime.now());
                        }

                        requestPartRepository.save(part);
                }

                request.setManagerNotes(decisionDTO.getManagerNotes());
                request.setManagerDecisionDate(LocalDateTime.now());
                if (anyPartial || anyRejected) {
                        request.setStatus(MaintenanceRequestStatus.PARTIALLY_APPROVED);
                } else if (anyApproved) {
                        request.setStatus(MaintenanceRequestStatus.APPROVED);
                } else {
                        request.setStatus(MaintenanceRequestStatus.UNDER_REVIEW);
                }

                MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);
                List<RequestPart> updatedParts = requestPartRepository.findByRequestRequestId(requestId);
                return convertToResponseDTO(savedRequest, updatedParts);
        }

        @Transactional
        public MaintenanceRequestResponseDTO rejectRequest(Long requestId, String rejectionReason) {
                Optional<MaintenanceRequest> requestOpt = maintenanceRequestRepository.findById(requestId);
                if (requestOpt.isEmpty()) {
			throw new IllegalArgumentException("Request not found");
		}

		MaintenanceRequest request = requestOpt.get();
		request.setStatus(MaintenanceRequestStatus.CLOSED);
		request.setManagerNotes(rejectionReason);
		request.setManagerDecisionDate(LocalDateTime.now());

		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
                parts.forEach(part -> {
                        part.setStatus(PartStatus.REJECTED);
                        part.setRejectionReason(rejectionReason);
                        requestPartRepository.save(part);
                });

		return convertToResponseDTO(savedRequest, parts);
	}

	@SuppressWarnings("unchecked")
	@Transactional
	public MaintenanceRequestResponseDTO orderParts(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));

		List<Map<String, Object>> items = (List<Map<String, Object>>) payload.getOrDefault("items", List.of());

		Map<Long, List<RequestPart>> partsBySupplier = items.stream()
				.map(item -> {
					Long partId = Long.valueOf(item.get("partId").toString());
					RequestPart part = requestPartRepository.findById(partId).orElseThrow(() -> new IllegalArgumentException("Part not found"));
					if (!part.getRequest().getRequestId().equals(requestId)) {
						throw new IllegalArgumentException("Part does not belong to the request");
					}
					Long supplierId = item.get("supplierId") != null ? Long.valueOf(item.get("supplierId").toString()) : null;
					if (supplierId == null) {
						throw new IllegalArgumentException("Supplier ID is required for part " + part.getPartName());
					}
					part.setSupplierId(supplierId);
					return part;
				})
				.collect(Collectors.groupingBy(RequestPart::getSupplierId));

		for (Map.Entry<Long, List<RequestPart>> entry : partsBySupplier.entrySet()) {
			Long supplierId = entry.getKey();
			List<RequestPart> supplierParts = entry.getValue();

			supplierService.createOrder(supplierId, req, supplierParts);

			for (RequestPart part : supplierParts) {
				part.setStatus(PartStatus.ORDERED);
				part.setOrderDate(LocalDateTime.now());
				requestPartRepository.save(part);
			}
		}

		req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
		maintenanceRequestRepository.save(req);
		List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
		return convertToResponseDTO(req, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO markDelivered(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		java.util.List<Long> partIds = ((java.util.List<Object>) payload.getOrDefault("partIds", java.util.List.of()))
				.stream().map(o -> Long.valueOf(o.toString())).toList();
		for (Long pid : partIds) {
			RequestPart part = requestPartRepository.findById(pid).orElseThrow(() -> new IllegalArgumentException("Part not found"));
			if (!part.getRequest().getRequestId().equals(requestId)) {
				throw new IllegalArgumentException("Part does not belong to the request");
			}
			part.setStatus(PartStatus.DELIVERED);
			part.setDeliveryDate(java.time.LocalDateTime.now());
			requestPartRepository.save(part);
		}
		req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
		maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
		return convertToResponseDTO(req, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO markIssued(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		java.util.List<Long> partIds = ((java.util.List<Object>) payload.getOrDefault("partIds", java.util.List.of()))
				.stream().map(o -> Long.valueOf(o.toString())).toList();
		for (Long pid : partIds) {
			RequestPart part = requestPartRepository.findById(pid).orElseThrow(() -> new IllegalArgumentException("Part not found"));
			if (!part.getRequest().getRequestId().equals(requestId)) {
				throw new IllegalArgumentException("Part does not belong to the request");
			}
			part.setStatus(PartStatus.INSTALLED);
			part.setIssueDate(java.time.LocalDateTime.now());
			requestPartRepository.save(part);

			try {
				partsCatalogRepository.findByCatalogNumber(part.getCatalogNumber()).ifPresent(catalogPart -> {
					ReservationRequestDto reservationRequest = new ReservationRequestDto(catalogPart.getCatalogId(), part.getQuantity(), req.getRequestId());
					inventoryService.reservePart(reservationRequest);
				});
			} catch (RuntimeException e) {
				throw new IllegalStateException("Ошибка списания запчасти '" + part.getPartName() + "' со склада: " + e.getMessage());
			}
		}
		req.setStatus(MaintenanceRequestStatus.DONE);
		maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
		return convertToResponseDTO(req, parts);
	}

        @Transactional
        public MaintenanceRequestResponseDTO closeRequest(Long requestId, java.util.Map<String, Object> payload) {
                MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
                req.setStatus(MaintenanceRequestStatus.CLOSED);
                req.setCompletionDate(java.time.LocalDateTime.now());
                maintenanceRequestRepository.save(req);
                java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
                return convertToResponseDTO(req, parts);
        }

        @Transactional
        public MaintenanceRequestResponseDTO completeRequest(Long requestId) {
                MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));

                MaintenanceRequestStatus currentStatus = req.getStatus();
                if (currentStatus == null) {
                        throw new IllegalStateException("Request status is not specified");
                }

                if (currentStatus == MaintenanceRequestStatus.DONE
                                || currentStatus == MaintenanceRequestStatus.CLOSED
                                || currentStatus == MaintenanceRequestStatus.UNREPAIRABLE) {
                        throw new IllegalStateException("Request is already completed or closed");
                }

                if (currentStatus != MaintenanceRequestStatus.APPROVED
                                && currentStatus != MaintenanceRequestStatus.IN_PROGRESS
                                && currentStatus != MaintenanceRequestStatus.PARTIALLY_APPROVED) {
                        throw new IllegalStateException("Only approved or in-progress requests can be completed");
                }

                req.setStatus(MaintenanceRequestStatus.DONE);
                req.setCompletionDate(LocalDateTime.now());
                maintenanceRequestRepository.save(req);

                java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
                return convertToResponseDTO(req, parts);
        }

        @Transactional
        public MaintenanceRequestResponseDTO markAsUnrepairable(Long requestId, String reason) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		req.setStatus(MaintenanceRequestStatus.UNREPAIRABLE);
		req.setManagerNotes(reason); 
		req.setCompletionDate(java.time.LocalDateTime.now());
		maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
		return convertToResponseDTO(req, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO publishRequest(Long requestId) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		if (req.getStatus() != MaintenanceRequestStatus.NEW) {
			throw new IllegalArgumentException("Only NEW requests can be published");
		}
		req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
		req.setPublishedAt(java.time.LocalDateTime.now());
		maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
		return convertToResponseDTO(req, parts);
	}

	@Transactional
        public MaintenanceRequestResponseDTO assignAgent(Long requestId, Long agentId) {
                MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
                                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
                req.setAssignedAgentId(agentId);
                req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
                maintenanceRequestRepository.save(req);
                java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(req.getRequestId());
                return convertToResponseDTO(req, parts);
        }

        private void notifyClubTeamAboutRequest(MaintenanceRequest request) {
                if (request == null) {
                        return;
                }

                List<BowlingClub> relatedClubs = new ArrayList<>();
                Set<Long> processedClubIds = new LinkedHashSet<>();

                BowlingClub requestClub = request.getClub();
                if (requestClub != null) {
                        Long clubId = requestClub.getClubId();
                        if (clubId == null || processedClubIds.add(clubId)) {
                                relatedClubs.add(requestClub);
                        }
                }

                MechanicProfile mechanic = request.getMechanic();
                if (mechanic != null) {
                        List<BowlingClub> mechanicClubs = Optional.ofNullable(mechanic.getClubs()).orElse(List.of());
                        for (BowlingClub mechanicClub : mechanicClubs) {
                                if (mechanicClub == null) {
                                        continue;
                                }
                                Long clubId = mechanicClub.getClubId();
                                if (clubId == null || processedClubIds.add(clubId)) {
                                        relatedClubs.add(mechanicClub);
                                }
                        }
                }

                List<OwnerProfile> owners = new ArrayList<>();
                Set<Long> processedOwnerIds = new LinkedHashSet<>();
                List<ManagerProfile> managers = new ArrayList<>();
                Set<Long> processedManagerIds = new LinkedHashSet<>();

                for (BowlingClub club : relatedClubs) {
                        if (club == null) {
                                continue;
                        }

                        OwnerProfile owner = club.getOwner();
                        if (owner != null) {
                                Long ownerKey = owner.getOwnerId() != null
                                                ? owner.getOwnerId()
                                                : (owner.getUser() != null ? owner.getUser().getUserId() : null);
                                if (ownerKey == null || processedOwnerIds.add(ownerKey)) {
                                        owners.add(owner);
                                }
                        }

                        Long relatedClubId = club.getClubId();
                        if (relatedClubId != null) {
                                List<ManagerProfile> clubManagers = managerProfileRepository.findByClub_ClubId(relatedClubId);
                                for (ManagerProfile manager : clubManagers) {
                                        if (manager == null) {
                                                continue;
                                        }
                                        Long managerKey = manager.getManagerId() != null
                                                        ? manager.getManagerId()
                                                        : (manager.getUser() != null ? manager.getUser().getUserId() : null);
                                        if (managerKey == null || processedManagerIds.add(managerKey)) {
                                                managers.add(manager);
                                        }
                                }
                        }
                }

                notificationService.notifyMaintenanceRequestCreated(request, owners, managers);
        }

        private MaintenanceRequestResponseDTO convertToResponseDTO(MaintenanceRequest request, List<RequestPart> parts) {
                BowlingClub club = request.getClub();
                Long clubId = club != null ? club.getClubId() : null;
                String clubName = club != null ? club.getName() : null;

                MechanicProfile mechanic = request.getMechanic();
                Long mechanicId = mechanic != null ? mechanic.getProfileId() : null;
                String mechanicName = mechanic != null ? mechanic.getFullName() : null;

                List<MaintenanceRequestResponseDTO.RequestPartResponseDTO> partDTOs = parts.stream()
                                .map(part -> {
                                        Supplier supplier = Optional.ofNullable(part.getPurchaseOrder())
                                                        .map(PurchaseOrder::getSupplier)
                                                        .orElse(null);
                                        return MaintenanceRequestResponseDTO.RequestPartResponseDTO.builder()
                                                        .partId(part.getPartId())
                                                        .catalogNumber(part.getCatalogNumber())
                                                        .partName(part.getPartName())
                                                        .quantity(part.getQuantity())
                                                        .inventoryId(part.getInventoryId())
                                                        .catalogId(part.getCatalogId())
                                                        .warehouseId(part.getWarehouseId())
                                                        .inventoryLocation(part.getInventoryLocation())
                                                        .status(part.getStatus() != null ? part.getStatus().name() : null)
                                                        .rejectionReason(part.getRejectionReason())
                                                        .supplierId(part.getSupplierId())
                                                        .supplierName(supplier != null ? supplier.getLegalName() : null)
                                                        .orderDate(part.getOrderDate())
                                                        .deliveryDate(part.getDeliveryDate())
                                                        .issueDate(part.getIssueDate())
                                                        .available(part.getIsAvailable())
                                                        .acceptedQuantity(part.getAcceptedQuantity())
                                                        .acceptanceComment(part.getAcceptanceComment())
                                                        .acceptanceDate(part.getAcceptanceDate())
                                                        // для UI механика и менеджера показываем, что нужна помощь
                                                        .helpRequested(part.getHelpRequested())
                                                        .build();
                                })
                                .collect(Collectors.toList());

                return MaintenanceRequestResponseDTO.builder()
                                .requestId(request.getRequestId())
                                .clubId(clubId)
                                .clubName(clubName)
                                .laneNumber(request.getLaneNumber())
                                .mechanicId(mechanicId)
                                .mechanicName(mechanicName)
                                .requestDate(request.getRequestDate())
                                .completionDate(request.getCompletionDate())
                                .status(request.getStatus() != null ? request.getStatus().name() : null)
                                .managerNotes(request.getManagerNotes())
                                .managerDecisionDate(request.getManagerDecisionDate())
                                .verificationStatus(request.getVerificationStatus())
                                .reason(request.getRequestReason())
                                .requestedParts(partDTOs)
                                .build();
        }
}
