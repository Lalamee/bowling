package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;

import java.util.Optional;
import java.util.List;

@Repository
public interface EquipmentComponentRepository extends JpaRepository<EquipmentComponent, Long> {

        Optional<EquipmentComponent> findByNameAndManufacturerAndCategory(String name, String manufacturer, String category);

        List<EquipmentComponent> findByParentIsNullOrderByComponentIdAsc();

        List<EquipmentComponent> findByParent_ComponentIdOrderByComponentIdAsc(Long parentId);
}
