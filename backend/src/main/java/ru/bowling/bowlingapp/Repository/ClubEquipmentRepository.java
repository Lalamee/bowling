package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.ClubEquipment;

@Repository
public interface ClubEquipmentRepository extends JpaRepository<ClubEquipment, Long> {
}
