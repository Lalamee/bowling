package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.EquipmentMaintenanceSchedule;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface EquipmentMaintenanceScheduleRepository extends JpaRepository<EquipmentMaintenanceSchedule, Long> {
    List<EquipmentMaintenanceSchedule> findByClubClubId(Long clubId);
    List<EquipmentMaintenanceSchedule> findByEquipmentEquipmentId(Long equipmentId);
    List<EquipmentMaintenanceSchedule> findByScheduledDateBefore(LocalDate date);
}
