package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.Supplier;

@Repository
public interface SupplierRepository extends JpaRepository<Supplier, Long> {
}
