package ru.bowling.bowlingapp.Entity.enums;

public enum WorkLogStatus {
    CREATED,       // Запись создана
    ASSIGNED,      // Назначена механику
    IN_PROGRESS,   // В работе
    ON_HOLD,       // Приостановлена (ожидание запчастей, дополнительной информации)
    COMPLETED,     // Выполнена
    VERIFIED,      // Проверена менеджером
    CLOSED,        // Закрыта
    CANCELLED      // Отменена
}
