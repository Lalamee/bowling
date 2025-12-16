package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.EquipmentCategoryDTO;
import ru.bowling.bowlingapp.Entity.EquipmentCategory;
import ru.bowling.bowlingapp.Repository.EquipmentCategoryRepository;

import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EquipmentCategoryService {

    private final EquipmentCategoryRepository equipmentCategoryRepository;

    public List<EquipmentCategoryDTO> getCategories(String brand, Long parentId, Integer level) {
        String normalizedBrand = normalizeBrand(brand);

        if (level != null && level > 1 && parentId == null) {
            throw new IllegalArgumentException("parentId is required for level " + level);
        }

        if (parentId == null) {
            return fetchRootCategories(normalizedBrand, level);
        }

        EquipmentCategory parent = equipmentCategoryRepository.findByIdAndIsActiveTrue(parentId)
                .orElse(null);
        if (parent == null) {
            return Collections.emptyList();
        }

        if (normalizedBrand != null && !normalizedBrand.equalsIgnoreCase(parent.getBrand())) {
            return Collections.emptyList();
        }

        int expectedLevel = parent.getLevel() + 1;
        if (level != null && !level.equals(expectedLevel)) {
            throw new IllegalArgumentException("Expected level " + expectedLevel + " for children of parent " + parentId);
        }

        List<EquipmentCategory> children = normalizedBrand == null
                ? equipmentCategoryRepository.findByParent_IdAndIsActiveTrueOrderBySortOrder(parentId)
                : equipmentCategoryRepository.findByParent_IdAndBrandIgnoreCaseAndIsActiveTrueOrderBySortOrder(parentId, normalizedBrand);

        return children.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private List<EquipmentCategoryDTO> fetchRootCategories(String normalizedBrand, Integer level) {
        if (level != null && level != 1) {
            throw new IllegalArgumentException("Root level must be 1 when parentId is not provided");
        }

        List<EquipmentCategory> roots = normalizedBrand == null
                ? equipmentCategoryRepository.findByParentIsNullAndIsActiveTrueOrderBySortOrder()
                : equipmentCategoryRepository.findByParentIsNullAndBrandIgnoreCaseAndIsActiveTrueOrderBySortOrder(normalizedBrand);

        return roots.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private String normalizeBrand(String brand) {
        return Optional.ofNullable(brand)
                .map(b -> b.toLowerCase(Locale.ROOT).trim())
                .filter(s -> !s.isBlank())
                .orElse(null);
    }

    private EquipmentCategoryDTO toDto(EquipmentCategory category) {
        String code = Optional.ofNullable(category.getCode())
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .orElseGet(() -> category.getId() != null ? category.getId().toString() : null);

        return EquipmentCategoryDTO.builder()
                .id(category.getId())
                .parentId(category.getParent() != null ? category.getParent().getId() : null)
                .level(category.getLevel())
                .brand(category.getBrand())
                .nameRu(category.getNameRu())
                .nameEn(category.getNameEn())
                .code(code)
                .sortOrder(category.getSortOrder())
                .active(category.isActive())
                .build();
    }
}
