package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.PartsCatalogResponseDTO;
import ru.bowling.bowlingapp.DTO.PartsSearchDTO;
import ru.bowling.bowlingapp.Entity.PartsCatalog;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Entity.enums.AvailabilityStatus;
import ru.bowling.bowlingapp.Repository.EquipmentCategoryRepository;
import ru.bowling.bowlingapp.Repository.PartImageRepository;
import ru.bowling.bowlingapp.Repository.PartsCatalogRepository;
import ru.bowling.bowlingapp.Repository.WarehouseInventoryRepository;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PartsService {

        private final PartsCatalogRepository partsCatalogRepository;
        private final WarehouseInventoryRepository warehouseInventoryRepository;
        private final PartImageRepository partImageRepository;
        private final EquipmentCategoryRepository equipmentCategoryRepository;

        @Transactional(readOnly = true)
        public List<PartsCatalogResponseDTO> searchParts(PartsSearchDTO searchDTO) {
		String query = (searchDTO.getSearchQuery() != null && !searchDTO.getSearchQuery().isBlank())
				? searchDTO.getSearchQuery().trim() : null;
                Integer manufacturerId = searchDTO.getManufacturerId() != null ? searchDTO.getManufacturerId().intValue() : null;
                Boolean isUnique = searchDTO.getIsUnique();
                String normalizedCategoryCode = (searchDTO.getCategoryCode() != null
                                && !searchDTO.getCategoryCode().trim().isBlank())
                                ? searchDTO.getCategoryCode().trim()
                                : null;
                List<String> categoryCodes = resolveCategoryCodes(normalizedCategoryCode);
                Sort sort = Sort.by(Sort.Direction.fromString(searchDTO.getSortDirection()), searchDTO.getSortBy());
                Pageable pageable = PageRequest.of(searchDTO.getPage(), searchDTO.getSize(), sort);

                Page<PartsCatalog> page = partsCatalogRepository.search(query, manufacturerId, isUnique, categoryCodes, pageable);
		List<PartsCatalog> parts = page.getContent();
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

        private List<String> resolveCategoryCodes(String normalizedCategoryCode) {
                if (normalizedCategoryCode == null || normalizedCategoryCode.isBlank()) {
                        return null;
                }

                try {
                        Long rootId = Long.parseLong(normalizedCategoryCode);
                        List<String> codes = new ArrayList<>();
                        ArrayDeque<Long> queue = new ArrayDeque<>();
                        queue.add(rootId);

                        while (!queue.isEmpty()) {
                                Long currentId = queue.poll();
                                codes.add(currentId.toString());

                                equipmentCategoryRepository.findByParent_IdAndIsActiveTrueOrderBySortOrder(currentId)
                                                .forEach(child -> queue.add(child.getId()));
                        }

                        return codes;
                } catch (NumberFormatException ignored) {
                        return List.of(normalizedCategoryCode);
                }
        }
}
