package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;

import java.util.Collection;
import java.util.List;

@Repository
public interface WarehouseInventoryRepository extends JpaRepository<WarehouseInventory, Long> {

    List<WarehouseInventory> findByCatalogId(Integer catalogId);

    List<WarehouseInventory> findByWarehouseId(Integer warehouseId);

    WarehouseInventory findFirstByWarehouseIdAndCatalogId(Integer warehouseId, Integer catalogId);

    List<WarehouseInventory> findByQuantityGreaterThan(Integer quantity);
    
    List<WarehouseInventory> findByCatalogIdAndQuantityGreaterThan(Integer catalogId, Integer quantity);

    @Query("select w.catalogId, sum(w.quantity) from WarehouseInventory w where w.catalogId in :catalogIds group by w.catalogId")
    List<Object[]> sumQuantitiesByCatalogIds(@Param("catalogIds") Collection<Integer> catalogIds);
}
