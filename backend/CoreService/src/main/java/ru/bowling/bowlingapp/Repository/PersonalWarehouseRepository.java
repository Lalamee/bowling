package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.PersonalWarehouse;

import java.util.List;

@Repository
public interface PersonalWarehouseRepository extends JpaRepository<PersonalWarehouse, Integer> {
    List<PersonalWarehouse> findByMechanicProfile_ProfileIdAndIsActiveTrue(Long profileId);
}
