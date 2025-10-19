package ru.bowling.bowlingapp.Entity.enums;

public enum PurchaseOrderStatus {
    PENDING,        // Ожидает подтверждения от поставщика
    CONFIRMED,      // Поставщик подтвердил
    REJECTED,       // Поставщик отклонил
    PARTIALLY_COMPLETED, // Частично выполнен
    COMPLETED,      // Выполнен
    CANCELED        // Отменен
}
