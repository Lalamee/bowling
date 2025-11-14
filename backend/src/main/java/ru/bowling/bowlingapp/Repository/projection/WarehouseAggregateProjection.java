package ru.bowling.bowlingapp.Repository.projection;

public interface WarehouseAggregateProjection {
    Integer getWarehouseId();
    Long getTotalItems();
    Long getLowItems();
    Long getReservedItems();
}
