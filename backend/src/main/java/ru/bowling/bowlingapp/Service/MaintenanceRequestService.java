package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestUpdateDTO;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.MaintenanceRequestRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.ManagerProfileRepository;
import ru.bowling.bowlingapp.Repository.AdministratorProfileRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.RequestPartRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
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
        private final AdministratorProfileRepository administratorProfileRepository;
        private final PartsCatalogRepository partsCatalogRepository;
        private final BowlingClubRepository bowlingClubRepository;
        private final ClubStaffRepository clubStaffRepository;
        private final UserRepository userRepository;
        private final WarehouseInventoryRepository warehouseInventoryRepository;
        private final InventoryService inventoryService;
        private final SupplierService supplierService;
        private final NotificationService notificationService;

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
                if (!mechanicWorksInClub(mechanicProfile, club)) {
                        throw new IllegalArgumentException("Mechanic is not assigned to the specified club");
                }

                validateRequestedParts(requestDTO.getRequestedParts(), club);

                if (requestDTO.getLaneNumber() == null || requestDTO.getLaneNumber() <= 0) {
                        throw new IllegalArgumentException("Lane number must be > 0");
                }

                MaintenanceRequest request = MaintenanceRequest.builder()
                                .club(club)
                                .laneNumber(requestDTO.getLaneNumber())
                                .mechanic(mechanicProfile)
				.requestDate(LocalDateTime.now())
				.status(MaintenanceRequestStatus.NEW)
				.managerNotes(requestDTO.getManagerNotes())
				.verificationStatus("NOT_VERIFIED")
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

                validateRequestedParts(partsToAdd, request.getClub());

                for (PartRequestDTO.RequestedPartDTO partDTO : partsToAdd) {
                        RequestPart requestPart = buildRequestPart(request, partDTO);
                        requestPartRepository.save(requestPart);
                }

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                return convertToResponseDTO(request, parts);
        }


	@Transactional
	public MaintenanceRequestResponseDTO updateRequest(Long requestId, MaintenanceRequestUpdateDTO updateDTO) {
		if (updateDTO == null) {
			throw new IllegalArgumentException("Update data is required");
		}

		MaintenanceRequest request = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));

		MaintenanceRequestStatus previousStatus = request.getStatus();

		if (updateDTO.getLaneNumber() != null) {
			if (updateDTO.getLaneNumber() <= 0) {
				throw new IllegalArgumentException("Lane number must be > 0");
			}
			request.setLaneNumber(updateDTO.getLaneNumber());
		}

		if (updateDTO.getManagerNotes() != null) {
			request.setManagerNotes(normalizeValue(updateDTO.getManagerNotes()));
		}

		MaintenanceRequestStatus targetStatus = parseStatus(updateDTO.getStatus());
		if (targetStatus != null && targetStatus != request.getStatus()) {
			request.setStatus(targetStatus);
			if (targetStatus == MaintenanceRequestStatus.APPROVED) {
				request.setManagerDecisionDate(LocalDateTime.now());
			}
			if (targetStatus == MaintenanceRequestStatus.CLOSED
					|| targetStatus == MaintenanceRequestStatus.UNREPAIRABLE
					|| targetStatus == MaintenanceRequestStatus.DONE) {
				request.setCompletionDate(LocalDateTime.now());
			}
		}

		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

		if (updateDTO.getRequestedParts() != null && !updateDTO.getRequestedParts().isEmpty()) {
			Map<Long, RequestPart> existingParts = requestPartRepository.findByRequestRequestId(requestId).stream()
					.filter(part -> part.getPartId() != null)
					.collect(Collectors.toMap(RequestPart::getPartId, part -> part, (left, right) -> left));

			for (MaintenanceRequestUpdateDTO.PartUpdateDTO partUpdate : updateDTO.getRequestedParts()) {
				if (partUpdate == null) {
					continue;
				}
				if (partUpdate.getPartId() != null) {
					RequestPart part = existingParts.get(partUpdate.getPartId());
					if (part == null) {
						throw new IllegalArgumentException("Part " + partUpdate.getPartId() + " not found in request");
					}
					applyPartUpdates(part, partUpdate);
					requestPartRepository.save(part);
				} else {
					PartRequestDTO.RequestedPartDTO newPart = PartRequestDTO.RequestedPartDTO.builder()
						.inventoryId(partUpdate.getInventoryId())
						.catalogId(partUpdate.getCatalogId())
						.catalogNumber(partUpdate.getCatalogNumber())
						.partName(partUpdate.getPartName())
						.quantity(partUpdate.getQuantity())
						.warehouseId(partUpdate.getWarehouseId())
						.location(partUpdate.getLocation())
						.build();
                                        validateRequestedParts(List.of(newPart), savedRequest.getClub());
					RequestPart requestPart = buildRequestPart(savedRequest, newPart);
					requestPartRepository.save(requestPart);
				}
			}
		}

		List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());

		notifyStatusChange(savedRequest, previousStatus);

		return convertToResponseDTO(savedRequest, parts);
	}

        private boolean mechanicWorksInClub(MechanicProfile mechanicProfile, BowlingClub club) {
                if (mechanicProfile == null || club == null) {
                        return false;
                }
                Long clubId = club.getClubId();
                boolean assignedDirectly = Optional.ofNullable(mechanicProfile.getClubs())
                                .orElse(List.of())
                                .stream()
                                .map(BowlingClub::getClubId)
                                .filter(Objects::nonNull)
                                .anyMatch(id -> id.equals(clubId));

                if (assignedDirectly) {
                        return true;
                }

                User mechanicUser = mechanicProfile.getUser();
                if (mechanicUser != null && clubStaffRepository.existsByClubAndUser(club, mechanicUser)) {
                        return true;
                }

                return false;
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

                if (clubStaffRepository.existsByClubAndUser(club, user)) {
                        return true;
                }

                ManagerProfile managerProfile = user.getManagerProfile();
                if (managerProfile != null && managerProfile.getClub() != null
                                && Objects.equals(managerProfile.getClub().getClubId(), club.getClubId())) {
                        return true;
                }

                AdministratorProfile administratorProfile = user.getAdministratorProfile();
                if (administratorProfile != null && administratorProfile.getClub() != null
                                && Objects.equals(administratorProfile.getClub().getClubId(), club.getClubId())) {
                        return true;
                }

                MechanicProfile mechanicProfile = user.getMechanicProfile();
                if (mechanicProfile != null && mechanicWorksInClub(mechanicProfile, club)) {
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

        private void validateRequestedParts(List<PartRequestDTO.RequestedPartDTO> parts, BowlingClub club) {
                if (parts == null || parts.isEmpty()) {
                        throw new IllegalArgumentException("Необходимо указать хотя бы одну запчасть");
                }

                Integer expectedWarehouseId = resolveWarehouseId(club != null ? club.getClubId() : null);

                for (PartRequestDTO.RequestedPartDTO partDTO : parts) {
                        if (partDTO == null) {
                                throw new IllegalArgumentException("Данные по запчасти обязательны");
                        }

                        Integer quantity = partDTO.getQuantity();
                        if (quantity == null || quantity <= 0) {
                                throw new IllegalArgumentException(
                                                "Количество для детали '" + safePartName(partDTO) + "' должно быть больше нуля");
                        }

                        if (expectedWarehouseId != null) {
                                Integer providedWarehouseId = partDTO.getWarehouseId();
                                if (providedWarehouseId != null && !Objects.equals(providedWarehouseId, expectedWarehouseId)) {
                                        throw new IllegalArgumentException(
                                                        "Запчасть '" + safePartName(partDTO)
                                                                        + "' относится к другому складу клуба");
                                }
                                if (providedWarehouseId == null) {
                                        partDTO.setWarehouseId(expectedWarehouseId);
                                }
                        }

                        WarehouseInventory inventory = null;
                        if (partDTO.getInventoryId() != null) {
                                inventory = warehouseInventoryRepository.findById(partDTO.getInventoryId())
                                                .orElseThrow(() -> new IllegalArgumentException(
                                                                "Позиция склада с идентификатором " + partDTO.getInventoryId()
                                                                                + " не найдена"));
                                if (expectedWarehouseId != null && inventory.getWarehouseId() != null
                                                && !Objects.equals(inventory.getWarehouseId(), expectedWarehouseId)) {
                                        throw new IllegalArgumentException(
                                                        "Запчасть '" + safePartName(partDTO)
                                                                        + "' не находится на складе выбранного клуба");
                                }
                                if (partDTO.getWarehouseId() == null) {
                                        partDTO.setWarehouseId(inventory.getWarehouseId());
                                }
                                if (partDTO.getCatalogId() == null && inventory.getCatalogId() != null) {
                                        partDTO.setCatalogId(Long.valueOf(inventory.getCatalogId()));
                                }
                                if (partDTO.getLocation() == null) {
                                        partDTO.setLocation(inventory.getLocationReference());
                                }
                        }

                        PartsCatalog catalog = resolveCatalogForPart(partDTO);
                        if (catalog != null) {
                                if (partDTO.getCatalogId() == null) {
                                        partDTO.setCatalogId(catalog.getCatalogId());
                                }
                                if (partDTO.getCatalogNumber() == null) {
                                        partDTO.setCatalogNumber(normalizeValue(catalog.getCatalogNumber()));
                                }
                                if (partDTO.getPartName() == null) {
                                        String derivedName = normalizeValue(catalog.getCommonName());
                                        if (derivedName == null) {
                                                derivedName = normalizeValue(catalog.getOfficialNameRu());
                                        }
                                        if (derivedName == null) {
                                                derivedName = normalizeValue(catalog.getOfficialNameEn());
                                        }
                                        if (derivedName != null) {
                                                partDTO.setPartName(derivedName);
                                        }
                                }
                                if (partDTO.getWarehouseId() == null && expectedWarehouseId != null) {
                                        partDTO.setWarehouseId(expectedWarehouseId);
                                }
                        }

                        String partName = normalizeValue(partDTO.getPartName());
                        if (partName == null) {
                                throw new IllegalArgumentException("Название запчасти обязательно для заполнения");
                        }
                        partDTO.setPartName(partName);
                        partDTO.setCatalogNumber(normalizeValue(partDTO.getCatalogNumber()));
                        partDTO.setLocation(normalizeValue(partDTO.getLocation()));
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
                                .status(null)
                                .inventoryId(inventoryId)
                                .catalogId(catalogId)
                                .warehouseId(warehouseId)
                                .inventoryLocation(location)
                                .build();
        }

        private void applyPartUpdates(RequestPart part, MaintenanceRequestUpdateDTO.PartUpdateDTO update) {
                if (part == null || update == null) {
                        return;
                }

                if (update.getCatalogNumber() != null) {
                        part.setCatalogNumber(normalizeValue(update.getCatalogNumber()));
                }

                if (update.getPartName() != null) {
                        part.setPartName(normalizeValue(update.getPartName()));
                }

                if (update.getQuantity() != null) {
                        if (update.getQuantity() <= 0) {
                                String partLabel = normalizeValue(part.getPartName());
                                if (partLabel == null && part.getCatalogNumber() != null) {
                                        partLabel = part.getCatalogNumber();
                                }
                                if (partLabel == null && part.getPartId() != null) {
                                        partLabel = part.getPartId().toString();
                                }
                                throw new IllegalArgumentException("Количество для детали '" + (partLabel != null ? partLabel : "неизвестная запчасть") + "' должно быть больше нуля");
                        }
                        part.setQuantity(update.getQuantity());
                }

                if (update.getInventoryId() != null) {
                        part.setInventoryId(update.getInventoryId());
                }

                if (update.getCatalogId() != null) {
                        part.setCatalogId(update.getCatalogId());
                }

                if (update.getWarehouseId() != null) {
                        part.setWarehouseId(update.getWarehouseId());
                }

                if (update.getLocation() != null) {
                        part.setInventoryLocation(normalizeValue(update.getLocation()));
                }
        }

        private PartsCatalog resolveCatalogForPart(PartRequestDTO.RequestedPartDTO partDTO) {
                if (partDTO == null) {
                        return null;
                }
                if (partDTO.getCatalogId() != null) {
                        return partsCatalogRepository.findById(partDTO.getCatalogId())
                                        .orElseThrow(() -> new IllegalArgumentException(
                                                        "Каталог с идентификатором " + partDTO.getCatalogId() + " не найден"));
                }
                String catalogNumber = normalizeValue(partDTO.getCatalogNumber());
                if (catalogNumber != null) {
                        return partsCatalogRepository.findByCatalogNumber(catalogNumber).orElse(null);
                }
                return null;
        }

        private Integer resolveWarehouseId(Long clubId) {
                if (clubId == null) {
                        return null;
                }
                try {
                        return Math.toIntExact(clubId);
                } catch (ArithmeticException ex) {
                        return null;
                }
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

        private MaintenanceRequestStatus parseStatus(String status) {
                if (status == null) {
                        return null;
                }
                String normalized = status.trim();
                if (normalized.isEmpty()) {
                        return null;
                }
                try {
                        return MaintenanceRequestStatus.valueOf(normalized.toUpperCase(Locale.ROOT));
                } catch (IllegalArgumentException ex) {
                        throw new IllegalArgumentException("Unknown status: " + status);
                }
        }

	@Transactional
	public MaintenanceRequestResponseDTO approveRequest(Long requestId, String managerNotes) {
		Optional<MaintenanceRequest> requestOpt = maintenanceRequestRepository.findById(requestId);
		if (requestOpt.isEmpty()) {
			throw new IllegalArgumentException("Request not found");
		}

                MaintenanceRequest request = requestOpt.get();
                MaintenanceRequestStatus previousStatus = request.getStatus();
                request.setStatus(MaintenanceRequestStatus.APPROVED);
                request.setManagerNotes(managerNotes);
                request.setManagerDecisionDate(LocalDateTime.now());

                MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

		List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
                parts.forEach(part -> {
                        part.setStatus(null);
                        requestPartRepository.save(part);
                });

                notifyStatusChange(savedRequest, previousStatus);

                return convertToResponseDTO(savedRequest, parts);
        }

	@Transactional
	public MaintenanceRequestResponseDTO rejectRequest(Long requestId, String rejectionReason) {
		Optional<MaintenanceRequest> requestOpt = maintenanceRequestRepository.findById(requestId);
		if (requestOpt.isEmpty()) {
			throw new IllegalArgumentException("Request not found");
		}

                MaintenanceRequest request = requestOpt.get();
                MaintenanceRequestStatus previousStatus = request.getStatus();
                request.setStatus(MaintenanceRequestStatus.CLOSED);
                request.setManagerNotes(rejectionReason);
                request.setManagerDecisionDate(LocalDateTime.now());

                MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

		List<RequestPart> parts = requestPartRepository.findByRequestRequestId(requestId);
		parts.forEach(part -> {
			part.setStatus(null);
                        part.setRejectionReason(rejectionReason);
                        requestPartRepository.save(part);
                });

                notifyStatusChange(savedRequest, previousStatus);

                return convertToResponseDTO(savedRequest, parts);
        }

	@SuppressWarnings("unchecked")
	@Transactional
	public MaintenanceRequestResponseDTO orderParts(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();

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
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO markDelivered(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();
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
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO markIssued(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();
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
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO closeRequest(Long requestId, java.util.Map<String, Object> payload) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();
		req.setStatus(MaintenanceRequestStatus.CLOSED);
		req.setCompletionDate(java.time.LocalDateTime.now());
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO markAsUnrepairable(Long requestId, String reason) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();
		req.setStatus(MaintenanceRequestStatus.UNREPAIRABLE);
		req.setManagerNotes(reason);
		req.setCompletionDate(java.time.LocalDateTime.now());
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO publishRequest(Long requestId) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		if (req.getStatus() != MaintenanceRequestStatus.NEW) {
			throw new IllegalArgumentException("Only NEW requests can be published");
		}
		MaintenanceRequestStatus previousStatus = req.getStatus();
		req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
		req.setPublishedAt(java.time.LocalDateTime.now());
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

	@Transactional
	public MaintenanceRequestResponseDTO assignAgent(Long requestId, Long agentId) {
		MaintenanceRequest req = maintenanceRequestRepository.findById(requestId)
				.orElseThrow(() -> new IllegalArgumentException("Request not found"));
		MaintenanceRequestStatus previousStatus = req.getStatus();
		req.setAssignedAgentId(agentId);
		req.setStatus(MaintenanceRequestStatus.IN_PROGRESS);
		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(req);
		java.util.List<RequestPart> parts = requestPartRepository.findByRequestRequestId(savedRequest.getRequestId());
		notifyStatusChange(savedRequest, previousStatus);
		return convertToResponseDTO(savedRequest, parts);
	}

        private void notifyClubTeamAboutRequest(MaintenanceRequest request) {
                if (request == null) {
                        return;
                }

                NotificationRecipients recipients = collectNotificationRecipients(request);
                notificationService.notifyMaintenanceRequestCreated(
                                request,
                                recipients.getOwners(),
                                recipients.getManagers(),
                                recipients.getAdministrators());
        }

        private void notifyStatusChange(MaintenanceRequest request, MaintenanceRequestStatus previousStatus) {
                if (request == null) {
                        return;
                }
                MaintenanceRequestStatus currentStatus = request.getStatus();
                if (Objects.equals(previousStatus, currentStatus)) {
                        return;
                }
                NotificationRecipients recipients = collectNotificationRecipients(request);
                notificationService.notifyMaintenanceRequestStatusChanged(
                                request,
                                previousStatus,
                                currentStatus,
                                recipients.getOwners(),
                                recipients.getManagers(),
                                recipients.getAdministrators());
        }

        private NotificationRecipients collectNotificationRecipients(MaintenanceRequest request) {
                if (request == null) {
                        return new NotificationRecipients(List.of(), List.of(), List.of());
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
                List<AdministratorProfile> administrators = new ArrayList<>();
                Set<Long> processedAdministratorIds = new LinkedHashSet<>();

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

                        Long clubId = club.getClubId();
                        if (clubId != null) {
                                List<ManagerProfile> clubManagers = managerProfileRepository.findByClub_ClubId(clubId);
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

                                List<AdministratorProfile> clubAdmins = administratorProfileRepository.findByClub_ClubId(clubId);
                                for (AdministratorProfile administrator : clubAdmins) {
                                        if (administrator == null) {
                                                continue;
                                        }
                                        Long adminKey = administrator.getAdministratorId() != null
                                                        ? administrator.getAdministratorId()
                                                        : (administrator.getUser() != null ? administrator.getUser().getUserId() : null);
                                        if (adminKey == null || processedAdministratorIds.add(adminKey)) {
                                                administrators.add(administrator);
                                        }
                                }
                        }
                }

                return new NotificationRecipients(owners, managers, administrators);
        }

        private static class NotificationRecipients {
                private final List<OwnerProfile> owners;
                private final List<ManagerProfile> managers;
                private final List<AdministratorProfile> administrators;

                NotificationRecipients(List<OwnerProfile> owners, List<ManagerProfile> managers, List<AdministratorProfile> administrators) {
                        this.owners = owners != null ? owners : List.of();
                        this.managers = managers != null ? managers : List.of();
                        this.administrators = administrators != null ? administrators : List.of();
                }

                List<OwnerProfile> getOwners() {
                        return owners;
                }

                List<ManagerProfile> getManagers() {
                        return managers;
                }

                List<AdministratorProfile> getAdministrators() {
                        return administrators;
                }
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
                                .requestedParts(partDTOs)
                                .build();
        }
}
