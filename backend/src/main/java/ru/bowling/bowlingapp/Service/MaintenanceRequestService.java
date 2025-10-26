package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.MaintenanceRequestResponseDTO;
import ru.bowling.bowlingapp.DTO.PartRequestDTO;
import ru.bowling.bowlingapp.DTO.ReservationRequestDto;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Entity.enums.PartStatus;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.MaintenanceRequestRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.RequestPartRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MaintenanceRequestService {

        private final MaintenanceRequestRepository maintenanceRequestRepository;
        private final RequestPartRepository requestPartRepository;
        private final MechanicProfileRepository mechanicProfileRepository;
        private final PartsCatalogRepository partsCatalogRepository;
        private final BowlingClubRepository bowlingClubRepository;
        private final ClubStaffRepository clubStaffRepository;
        private final UserRepository userRepository;
        private final InventoryService inventoryService;
        private final SupplierService supplierService;
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
                if (clubId == null) {
                        return false;
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

                if (clubStaffRepository.existsByClubAndUser(club, user)) {
                        return true;
                }

                ManagerProfile managerProfile = user.getManagerProfile();
                if (managerProfile != null && managerProfile.getClub() != null
                                && Objects.equals(managerProfile.getClub().getClubId(), club.getClubId())) {
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

                        Integer quantity = partDTO.getQuantity();
                        if (quantity == null || quantity <= 0) {
                                throw new IllegalArgumentException("Количество для детали '" + safePartName(partDTO) + "' должно быть больше нуля");
                        }
                }
        }

        private WarehouseInventory resolveInventory(PartRequestDTO.RequestedPartDTO partDTO) {
                if (partDTO == null) {
                        return null;
                }

                if (partDTO.getInventoryId() != null) {
                        return warehouseInventoryRepository.findById(partDTO.getInventoryId())
                                .orElseThrow(() -> new IllegalArgumentException("Запчасть '" + safePartName(partDTO) + "' не найдена на складе"));
                }

                Integer warehouseId = partDTO.getWarehouseId();

                if (partDTO.getCatalogId() != null) {
                        List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(partDTO.getCatalogId().intValue());
                        WarehouseInventory selected = selectInventoryForWarehouse(inventories, warehouseId);
                        if (selected != null) {
                                return selected;
                        }
                }

                String catalogNumber = normalizeValue(partDTO.getCatalogNumber());
                if (catalogNumber != null) {
                        PartsCatalog catalogPart = partsCatalogRepository.findByCatalogNumber(catalogNumber).orElse(null);
                        if (catalogPart != null && catalogPart.getCatalogId() != null) {
                                List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(catalogPart.getCatalogId().intValue());
                                WarehouseInventory selected = selectInventoryForWarehouse(inventories, warehouseId);
                                if (selected != null) {
                                        return selected;
                                }
                        }
                }

                String partName = normalizeValue(partDTO.getPartName());
                if (partName != null) {
                        List<PartsCatalog> catalogMatches = partsCatalogRepository.findByAnyNameIgnoreCase(partName);
                        for (PartsCatalog catalog : catalogMatches) {
                                if (catalog.getCatalogId() == null) {
                                        continue;
                                }
                                List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(catalog.getCatalogId().intValue());
                                WarehouseInventory selected = selectInventoryForWarehouse(inventories, warehouseId);
                                if (selected != null) {
                                        return selected;
                                }
                        }
                }

                return null;
        }

        private PartsCatalog resolveCatalog(PartRequestDTO.RequestedPartDTO partDTO, WarehouseInventory inventory) {
                if (partDTO != null && partDTO.getCatalogId() != null) {
                        return partsCatalogRepository.findById(partDTO.getCatalogId())
                                .orElseThrow(() -> new IllegalArgumentException("Запчасть не найдена в каталоге"));
                }

                if (inventory != null && inventory.getCatalogId() != null) {
                        return partsCatalogRepository.findById(Long.valueOf(inventory.getCatalogId()))
                                .orElseThrow(() -> new IllegalArgumentException("Запчасть не найдена в каталоге"));
                }

                if (partDTO != null && partDTO.getCatalogNumber() != null) {
                        return partsCatalogRepository.findByCatalogNumber(partDTO.getCatalogNumber())
                                .orElseThrow(() -> new IllegalArgumentException("Запчасть с номером '" + partDTO.getCatalogNumber() + "' не найдена в каталоге."));
                }

                String partName = partDTO != null ? normalizeValue(partDTO.getPartName()) : null;
                if (partName != null) {
                        List<PartsCatalog> matches = partsCatalogRepository.findByAnyNameIgnoreCase(partName);
                        if (!matches.isEmpty()) {
                                if (inventory != null && inventory.getCatalogId() != null) {
                                        Long catalogId = Long.valueOf(inventory.getCatalogId());
                                        return matches.stream()
                                                .filter(match -> Objects.equals(match.getCatalogId(), catalogId))
                                                .findFirst()
                                                .orElse(matches.get(0));
                                }
                                return matches.get(0);
                        }
                }

                return null;
        }

        private RequestPart buildRequestPart(MaintenanceRequest request, PartRequestDTO.RequestedPartDTO partDTO) {
                if (request == null) {
                        throw new IllegalArgumentException("Request is required");
                }
                if (partDTO == null) {
                        throw new IllegalArgumentException("Part data is required");
                }

                WarehouseInventory inventory = resolveInventory(partDTO);
                if (inventory == null) {
                        throw new IllegalArgumentException("Запчасть '" + safePartName(partDTO) + "' не найдена на складе клуба");
                }

                PartsCatalog catalogPart = resolveCatalog(partDTO, inventory);
                if (catalogPart == null) {
                        throw new IllegalArgumentException("Запчасть '" + safePartName(partDTO) + "' не найдена в каталоге.");
                }

                String catalogNumber = resolveCatalogNumber(partDTO, catalogPart);
                String partName = resolvePartName(partDTO, catalogPart);
                Integer warehouseId = resolveWarehouseId(partDTO, inventory, request.getClub());
                String location = resolveInventoryLocation(partDTO, inventory);
                Long catalogId = catalogPart.getCatalogId();
                if (catalogId == null) {
                        throw new IllegalArgumentException("Каталожная запись для детали '" + partName + "' не содержит идентификатор");
                }

                return RequestPart.builder()
                                .request(request)
                                .catalogNumber(catalogNumber)
                                .partName(partName)
                                .quantity(partDTO.getQuantity())
                                .status(null)
                                .inventoryId(resolveInventoryId(partDTO, inventory))
                                .catalogId(catalogId)
                                .warehouseId(warehouseId)
                                .inventoryLocation(location)
                                .build();
        }

        private WarehouseInventory selectInventoryForWarehouse(List<WarehouseInventory> inventories, Integer warehouseId) {
                if (inventories == null || inventories.isEmpty()) {
                        return null;
                }

                if (warehouseId != null) {
                        Optional<WarehouseInventory> preferred = inventories.stream()
                                        .filter(inv -> Objects.equals(inv.getWarehouseId(), warehouseId))
                                        .filter(inv -> inv.getQuantity() != null && inv.getQuantity() > 0)
                                        .findFirst();
                        if (preferred.isPresent()) {
                                return preferred.get();
                        }

                        Optional<WarehouseInventory> sameWarehouse = inventories.stream()
                                        .filter(inv -> Objects.equals(inv.getWarehouseId(), warehouseId))
                                        .findFirst();
                        if (sameWarehouse.isPresent()) {
                                return sameWarehouse.get();
                        }
                }

                return inventories.stream()
                                .filter(inv -> inv.getQuantity() != null && inv.getQuantity() > 0)
                                .findFirst()
                                .orElse(inventories.get(0));
        }

        private Long resolveInventoryId(PartRequestDTO.RequestedPartDTO partDTO, WarehouseInventory inventory) {
                if (inventory != null && inventory.getInventoryId() != null) {
                        return inventory.getInventoryId();
                }
                return partDTO != null ? partDTO.getInventoryId() : null;
        }

        private Integer resolveWarehouseId(PartRequestDTO.RequestedPartDTO partDTO, WarehouseInventory inventory, BowlingClub club) {
                if (inventory != null && inventory.getWarehouseId() != null) {
                        return inventory.getWarehouseId();
                }
                if (partDTO != null && partDTO.getWarehouseId() != null) {
                        return partDTO.getWarehouseId();
                }
                if (club != null && club.getClubId() != null) {
                        try {
                                return Math.toIntExact(club.getClubId());
                        } catch (ArithmeticException ignored) {
                                return null;
                        }
                }
                return null;
        }

        private String resolveInventoryLocation(PartRequestDTO.RequestedPartDTO partDTO, WarehouseInventory inventory) {
                if (inventory != null) {
                        String location = inventory.getLocationReference();
                        if (location != null && !location.trim().isEmpty()) {
                                return location;
                        }
                }
                return partDTO != null ? partDTO.getLocation() : null;
        }

        private String resolveCatalogNumber(PartRequestDTO.RequestedPartDTO partDTO, PartsCatalog catalogPart) {
                String candidate = normalizeValue(partDTO != null ? partDTO.getCatalogNumber() : null);
                if (candidate != null) {
                        return candidate;
                }
                if (catalogPart != null) {
                        String fromCatalog = normalizeValue(catalogPart.getCatalogNumber());
                        if (fromCatalog != null) {
                                return fromCatalog;
                        }
                        if (catalogPart.getCatalogId() != null) {
                                return catalogPart.getCatalogId().toString();
                        }
                }
                if (partDTO != null && partDTO.getCatalogId() != null) {
                        return partDTO.getCatalogId().toString();
                }
                if (partDTO != null && partDTO.getInventoryId() != null) {
                        return partDTO.getInventoryId().toString();
                }
                return "UNKNOWN";
        }

        private String resolvePartName(PartRequestDTO.RequestedPartDTO partDTO, PartsCatalog catalogPart) {
                String candidate = normalizeValue(partDTO != null ? partDTO.getPartName() : null);
                if (candidate != null) {
                        return candidate;
                }

                if (catalogPart != null) {
                        String[] candidates = {
                                        catalogPart.getCommonName(),
                                        catalogPart.getOfficialNameRu(),
                                        catalogPart.getOfficialNameEn(),
                                        catalogPart.getCatalogNumber()
                        };
                        for (String value : candidates) {
                                String normalized = normalizeValue(value);
                                if (normalized != null) {
                                        return normalized;
                                }
                        }
                        if (catalogPart.getCatalogId() != null) {
                                return catalogPart.getCatalogId().toString();
                        }
                }

                String fallback = partDTO != null ? normalizeValue(partDTO.getCatalogNumber()) : null;
                if (fallback != null) {
                        return fallback;
                }
                if (partDTO != null && partDTO.getInventoryId() != null) {
                        return partDTO.getInventoryId().toString();
                }
                return "Неизвестная запчасть";
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

	@Transactional
	public MaintenanceRequestResponseDTO approveRequest(Long requestId, String managerNotes) {
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
		parts.forEach(part -> {
			part.setStatus(null);
			requestPartRepository.save(part);
		});

		return convertToResponseDTO(savedRequest, parts);
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
			part.setStatus(null);
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
