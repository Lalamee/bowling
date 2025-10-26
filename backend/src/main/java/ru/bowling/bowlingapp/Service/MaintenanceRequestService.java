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
import ru.bowling.bowlingapp.Repository.MaintenanceRequestRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.RequestPartRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MaintenanceRequestService {

	private final MaintenanceRequestRepository maintenanceRequestRepository;
	private final RequestPartRepository requestPartRepository;
	private final MechanicProfileRepository mechanicProfileRepository;
	private final PartsCatalogRepository partsCatalogRepository;
	private final InventoryService inventoryService; 
	private final SupplierService supplierService; 

        @Transactional
        public MaintenanceRequestResponseDTO createPartRequest(PartRequestDTO requestDTO) {
                Optional<MechanicProfile> mechanic = mechanicProfileRepository.findById(requestDTO.getMechanicId());
                if (mechanic.isEmpty()) {
                        throw new IllegalArgumentException("Mechanic not found");
                }

                validateRequestedParts(requestDTO.getRequestedParts());

		if (requestDTO.getClubId() == null) {
			throw new IllegalArgumentException("Club is required");
		}
		if (requestDTO.getLaneNumber() == null || requestDTO.getLaneNumber() <= 0) {
			throw new IllegalArgumentException("Lane number must be > 0");
		}
		BowlingClub club = BowlingClub.builder()
				.clubId(requestDTO.getClubId())
				.build();

		MaintenanceRequest request = MaintenanceRequest.builder()
				.club(club)
				.laneNumber(requestDTO.getLaneNumber())
				.mechanic(mechanic.get())
				.requestDate(LocalDateTime.now())
				.status(MaintenanceRequestStatus.NEW)
				.managerNotes(requestDTO.getManagerNotes())
				.verificationStatus("NOT_VERIFIED")
				.build();

		MaintenanceRequest savedRequest = maintenanceRequestRepository.save(request);

		List<RequestPart> requestParts = requestDTO.getRequestedParts().stream()
				.map(partDTO -> {
					RequestPart requestPart = RequestPart.builder()
							.request(savedRequest)
							.catalogNumber(partDTO.getCatalogNumber())
							.partName(partDTO.getPartName())
							.quantity(partDTO.getQuantity())
							.status(null)
							.build();
					return requestPartRepository.save(requestPart);
				})
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
        public List<MaintenanceRequestResponseDTO> getRequestsByClub(Long clubId) {
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
                                || request.getStatus() == MaintenanceRequestStatus.COMPLETED
                                || request.getStatus() == MaintenanceRequestStatus.DONE) {
                        throw new IllegalStateException("Parts cannot be added to closed or completed requests");
                }

                validateRequestedParts(partsToAdd);

                for (PartRequestDTO.RequestedPartDTO partDTO : partsToAdd) {
                        RequestPart requestPart = RequestPart.builder()
                                        .request(request)
                                        .catalogNumber(partDTO.getCatalogNumber())
                                        .partName(partDTO.getPartName())
                                        .quantity(partDTO.getQuantity())
                                        .status(null)
                                        .build();
                        requestPartRepository.save(requestPart);
                }

                List<RequestPart> parts = requestPartRepository.findByRequestRequestId(request.getRequestId());
                return convertToResponseDTO(request, parts);
        }

        private void validateRequestedParts(List<PartRequestDTO.RequestedPartDTO> parts) {
                if (parts == null || parts.isEmpty()) {
                        throw new IllegalArgumentException("At least one part must be provided");
                }

                for (PartRequestDTO.RequestedPartDTO partDTO : parts) {
                        String catalogNumber = partDTO.getCatalogNumber();
                        if (catalogNumber == null || catalogNumber.trim().isEmpty()) {
                                throw new IllegalArgumentException("Catalog number is required");
                        }

                        PartsCatalog catalogPart = partsCatalogRepository.findByCatalogNumber(catalogNumber)
                                        .orElseThrow(() -> new IllegalArgumentException("Запчасть с номером '" + catalogNumber + "' не найдена в каталоге."));
                        try {
                                inventoryService.reservePart(new ReservationRequestDto(catalogPart.getCatalogId(), partDTO.getQuantity(), null));
                                inventoryService.releasePart(new ReservationRequestDto(catalogPart.getCatalogId(), partDTO.getQuantity(), null));
                        } catch (RuntimeException e) {
                                throw new IllegalArgumentException("Ошибка проверки запчасти '" + partDTO.getPartName() + "': " + e.getMessage());
                        }
                }
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
