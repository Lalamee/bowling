package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.PartsCatalogCreateDTO;
import ru.bowling.bowlingapp.DTO.PartsCatalogResponseDTO;
import ru.bowling.bowlingapp.DTO.PartsSearchDTO;
import ru.bowling.bowlingapp.Entity.EquipmentCategory;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Entity.enums.AvailabilityStatus;
import ru.bowling.bowlingapp.Repository.EquipmentCategoryRepository;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;
import ru.bowling.bowlingapp.Repository.PartImageRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class PartsService {

        private final PartsCatalogRepository partsCatalogRepository;
        private final WarehouseInventoryRepository warehouseInventoryRepository;
        private final PartImageRepository partImageRepository;
        private final EquipmentCategoryRepository equipmentCategoryRepository;
        private final EquipmentComponentRepository equipmentComponentRepository;

        @Transactional(readOnly = true)
        public List<PartsCatalogResponseDTO> searchParts(PartsSearchDTO searchDTO) {
                String query = (searchDTO.getSearchQuery() != null && !searchDTO.getSearchQuery().isBlank())
                                ? searchDTO.getSearchQuery().trim()
                                : null;
                String catalogNumberFilter = (searchDTO.getCatalogNumber() != null && !searchDTO.getCatalogNumber().isBlank())
                                ? searchDTO.getCatalogNumber().trim()
                                : null;
                Integer manufacturerId = (searchDTO.getManufacturerId() != null && searchDTO.getManufacturerId() > 0)
                                ? searchDTO.getManufacturerId().intValue()
                                : null;
                Boolean isUnique = searchDTO.getIsUnique();
                String normalizedCategoryCode = (searchDTO.getCategoryCode() != null
                                && !searchDTO.getCategoryCode().trim().isBlank())
                                ? searchDTO.getCategoryCode().trim()
                                : null;
                String componentRootCode = resolveComponentCode(searchDTO.getComponentId());
                List<String> categoryCodes = resolveCategoryCodes(componentRootCode != null ? componentRootCode
                                : normalizedCategoryCode);
                Sort sort = Sort.by(resolveSortDirection(searchDTO.getSortDirection()),
                                resolveSortBy(searchDTO.getSortBy()));
                Pageable pageable = PageRequest.of(resolvePage(searchDTO.getPage()),
                                resolvePageSize(searchDTO.getSize()), sort);

                Page<PartsCatalog> page = partsCatalogRepository.search(query, manufacturerId, isUnique, categoryCodes, pageable);
                List<PartsCatalog> parts = page.getContent();

                if (parts.isEmpty() && categoryCodes != null && !categoryCodes.isEmpty()) {
                        Page<PartsCatalog> fallbackPage = partsCatalogRepository.search(query, manufacturerId, isUnique, null,
                                        pageable);

                        parts = fallbackPage.getContent().stream()
                                        .filter(part -> part.getCategoryCode() != null)
                                        .filter(part -> categoryCodes.contains(part.getCategoryCode().trim().toLowerCase()))
                                        .toList();
                }
                if (catalogNumberFilter != null) {
                        String loweredFilter = catalogNumberFilter.toLowerCase();
                        parts = parts.stream()
                                        .filter(part -> part.getCatalogNumber() != null
                                                        && part.getCatalogNumber().toLowerCase().contains(loweredFilter))
                                        .toList();
                }
                if (query == null && catalogNumberFilter != null && parts.isEmpty()) {
                        parts = partsCatalogRepository.findByCatalogNumberContainingIgnoreCase(catalogNumberFilter);
                }
                Map<Integer, Integer> totals = warehouseInventoryRepository
                                .sumQuantitiesByCatalogIds(parts.stream().map(p -> p.getCatalogId().intValue()).toList())
                                .stream().collect(Collectors.toMap(
                                        row -> (Integer) row[0],
					row -> ((Number) row[1]).intValue()
				));
		return parts.stream().map(p -> convertToResponseDTO(p, totals.getOrDefault(p.getCatalogId().intValue(), 0)))
				.collect(Collectors.toList());
	}

	@Transactional(readOnly = true)
	public Optional<PartsCatalogResponseDTO> getPartByCatalogNumber(String catalogNumber) {
		return partsCatalogRepository.findByCatalogNumber(catalogNumber)
				.map(this::convertToResponseDTO);
	}

        @Transactional(readOnly = true)
        public List<PartsCatalogResponseDTO> getUniqueParts() {
                List<PartsCatalog> parts = partsCatalogRepository.findByIsUniqueTrue();
                Map<Integer, Integer> totals = warehouseInventoryRepository
                                .sumQuantitiesByCatalogIds(parts.stream().map(p -> p.getCatalogId().intValue()).toList())
				.stream().collect(Collectors.toMap(
					row -> (Integer) row[0],
					row -> ((Number) row[1]).intValue()
				));
		return parts.stream()
                                .map(p -> convertToResponseDTO(p, totals.getOrDefault(p.getCatalogId().intValue(), 0)))
                                .collect(Collectors.toList());
        }

        @Transactional
        public PartsCatalogResponseDTO findOrCreateCatalog(PartsCatalogCreateDTO payload) {
                if (payload == null || payload.getCatalogNumber() == null || payload.getCatalogNumber().isBlank()) {
                        throw new IllegalArgumentException("Каталожный номер обязателен");
                }
                String normalizedNumber = payload.getCatalogNumber().trim();
                String normalizedName = payload.getName() != null && !payload.getName().trim().isEmpty()
                                ? payload.getName().trim()
                                : normalizedNumber;

                PartsCatalog part = Stream.concat(
                                partsCatalogRepository.findByCatalogNumber(normalizedNumber).stream(),
                                partsCatalogRepository.findByCatalogNumberContainingIgnoreCase(normalizedNumber)
                                                .stream()
                                                .filter(existing -> existing.getCatalogNumber() != null
                                                                && existing.getCatalogNumber().equalsIgnoreCase(normalizedNumber)))
                                .findFirst()
                                .orElseGet(() -> partsCatalogRepository.save(PartsCatalog.builder()
                                                .catalogNumber(normalizedNumber)
                                                .commonName(normalizedName)
                                                .officialNameRu(normalizedName)
                                                .officialNameEn(normalizedName)
                                                .description(payload.getDescription())
                                                .categoryCode(payload.getCategoryCode())
                                                .isUnique(payload.getIsUnique())
                                                .build()));

                return convertCommon(part, 0, AvailabilityStatus.NOT_AVAILABLE);
        }

        private PartsCatalogResponseDTO convertToResponseDTO(PartsCatalog part) {
                List<WarehouseInventory> inventories = warehouseInventoryRepository.findByCatalogId(part.getCatalogId().intValue());
                int totalQuantity = inventories.stream().mapToInt(WarehouseInventory::getQuantity).sum();
                AvailabilityStatus availabilityStatus = totalQuantity > 0 ? AvailabilityStatus.AVAILABLE : AvailabilityStatus.NOT_AVAILABLE;

                return convertCommon(part, totalQuantity, availabilityStatus);
        }

	private PartsCatalogResponseDTO convertToResponseDTO(PartsCatalog part, int totalQuantity) {
		AvailabilityStatus availabilityStatus = totalQuantity > 0 ? AvailabilityStatus.AVAILABLE : AvailabilityStatus.NOT_AVAILABLE;
		return convertCommon(part, totalQuantity, availabilityStatus);
	}

        private PartsCatalogResponseDTO convertCommon(PartsCatalog part, int totalQuantity, AvailabilityStatus availabilityStatus) {
                return PartsCatalogResponseDTO.builder()
                                .catalogId(part.getCatalogId())
                                .manufacturerId(part.getManufacturer() != null ? part.getManufacturer().getManufacturerId().longValue() : null)
                                .manufacturerName(part.getManufacturer() != null ? part.getManufacturer().getName() : null)
                                .catalogNumber(part.getCatalogNumber())
				.officialNameEn(part.getOfficialNameEn())
				.officialNameRu(part.getOfficialNameRu())
				.commonName(part.getCommonName())
                                .description(part.getDescription())
                                .normalServiceLife(part.getNormalServiceLife())
                                .unit(part.getUnit())
                                .isUnique(part.getIsUnique())
                                .categoryCode(part.getCategoryCode())
                                .availableQuantity(totalQuantity)
                                .availabilityStatus(availabilityStatus)
                                .imageUrl(resolveImageUrl(part.getCatalogId()))
                                .diagramUrl(null)
                                .equipmentNodeId(null)
                                .equipmentNodePath(List.of())
                                .compatibleEquipment(List.of())
                                .build();
        }

        private String resolveImageUrl(Long catalogId) {
                if (catalogId == null) {
                        return null;
                }
                return partImageRepository.findFirstByCatalogId(catalogId)
                                .map(image -> image.getImageUrl())
                                .orElse(null);
        }

        private int resolvePage(Integer requestedPage) {
                if (requestedPage == null || requestedPage < 0) {
                        return 0;
                }
                return requestedPage;
        }

        private int resolvePageSize(Integer requestedSize) {
                if (requestedSize == null || requestedSize <= 0) {
                        return 20;
                }
                return requestedSize;
        }

        private String resolveSortBy(String requestedSort) {
                return Optional.ofNullable(requestedSort)
                                .map(String::trim)
                                .filter(s -> !s.isBlank())
                                .orElse("catalogId");
        }

        private Sort.Direction resolveSortDirection(String requestedDirection) {
                return Optional.ofNullable(requestedDirection)
                                .map(String::trim)
                                .filter(s -> !s.isBlank())
                                .map(value -> {
                                        try {
                                                return Sort.Direction.fromString(value);
                                        } catch (IllegalArgumentException ignored) {
                                                return null;
                                        }
                                })
                                .orElse(Sort.Direction.ASC);
        }

        private List<String> resolveCategoryCodes(String normalizedCategoryCode) {
                if (normalizedCategoryCode == null || normalizedCategoryCode.isBlank()) {
                        return null;
                }

                List<String> rawCodes = new ArrayList<>();

                try {
                        Long rootId = Long.parseLong(normalizedCategoryCode);

                        equipmentCategoryRepository.findByIdAndIsActiveTrue(rootId).ifPresent(root -> {
                                ArrayDeque<EquipmentCategory> queue = new ArrayDeque<>();
                                queue.add(root);

                                while (!queue.isEmpty()) {
                                        EquipmentCategory current = queue.poll();

                                        if (current.getId() != null) {
                                                rawCodes.add(current.getId().toString());
                                        }
                                        if (current.getCode() != null && !current.getCode().isBlank()) {
                                                rawCodes.add(current.getCode());
                                        }

                                        equipmentCategoryRepository
                                                        .findByParent_IdAndIsActiveTrueOrderBySortOrder(current.getId())
                                                        .forEach(queue::add);
                                }
                        });

                        if (rawCodes.isEmpty()) {
                                rawCodes.add(normalizedCategoryCode);
                        }

                        return normalizeCodesList(rawCodes);
                } catch (NumberFormatException ignored) {
                        return normalizeCodesList(List.of(normalizedCategoryCode));
                }
        }

        private List<String> normalizeCodesList(List<String> codes) {
                List<String> cleaned = codes.stream()
                                .filter(code -> code != null && !code.isBlank())
                                .map(code -> code.trim().toLowerCase())
                                .distinct()
                                .toList();

                return cleaned.isEmpty() ? null : cleaned;
        }

        private String resolveComponentCode(Long componentId) {
                if (componentId == null) {
                        return null;
                }
                return equipmentComponentRepository.findById(componentId)
                                .map(component -> component.getCode() != null ? component.getCode().trim() : null)
                                .orElse(null);
        }
}
