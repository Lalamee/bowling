package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;

import java.util.Optional;

@Repository
public interface EquipmentComponentRepository extends JpaRepository<EquipmentComponent, Long> {

        Optional<EquipmentComponent> findByNameAndManufacturerAndCategory(String name, String manufacturer, String category);
}
