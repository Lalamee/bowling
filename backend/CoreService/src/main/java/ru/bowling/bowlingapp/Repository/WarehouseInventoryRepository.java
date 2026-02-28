package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.WarehouseInventory;
import ru.bowling.bowlingapp.Repository.projection.WarehouseAggregateProjection;

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

    @Query("""
            select w.warehouseId as warehouseId,
                   count(w.inventoryId) as totalItems,
                   sum(case when coalesce(w.quantity, 0) <= :threshold then 1 else 0 end) as lowItems,
                   sum(coalesce(w.reservedQuantity, 0)) as reservedItems
            from WarehouseInventory w
            where w.warehouseId in :warehouseIds
            group by w.warehouseId
            """)
    List<WarehouseAggregateProjection> aggregateByWarehouseIds(@Param("warehouseIds") Collection<Integer> warehouseIds,
                                                               @Param("threshold") Integer threshold);
}
