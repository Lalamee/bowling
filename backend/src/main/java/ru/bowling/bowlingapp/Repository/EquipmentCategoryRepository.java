package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.EquipmentCategory;

import java.util.List;
import java.util.Optional;

@Repository
public interface EquipmentCategoryRepository extends JpaRepository<EquipmentCategory, Long> {

    List<EquipmentCategory> findByParentIsNullAndIsActiveTrueOrderBySortOrder();

    List<EquipmentCategory> findByParentIsNullAndBrandIgnoreCaseAndIsActiveTrueOrderBySortOrder(String brand);

    List<EquipmentCategory> findByParent_IdAndIsActiveTrueOrderBySortOrder(Long parentId);

    List<EquipmentCategory> findByParent_IdAndBrandIgnoreCaseAndIsActiveTrueOrderBySortOrder(Long parentId, String brand);

    Optional<EquipmentCategory> findByIdAndIsActiveTrue(Long id);
}
