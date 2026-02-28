package ru.bowling.bowlingapp.Entity.enums;

import java.util.Arrays;

public enum WorkType {
    PREVENTIVE_MAINTENANCE("PREVENTIVE_MAINTENANCE"),    // Профилактическое обслуживание
    CORRECTIVE_MAINTENANCE("CORRECTIVE_MAINTENANCE"),    // Корректирующее обслуживание (ремонт)
    EMERGENCY_REPAIR("EMERGENCY_REPAIR"),                // Экстренный ремонт
    INSTALLATION("INSTALLATION"),                        // Установка нового оборудования
    REPLACEMENT("REPLACEMENT"),                          // Замена оборудования/запчастей
    INSPECTION("INSPECTION"),                            // Инспекция/диагностика
    CLEANING("CLEANING"),                                // Очистка оборудования
    CALIBRATION("CALIBRATION"),                          // Калибровка/настройка
    UPGRADE("UPGRADE"),                                  // Модернизация
    OTHER("OTHER"),                                      // Прочие работы
    MAINTENANCE("PREVENTIVE_MAINTENANCE"),               // Упрощенное значение для профилактических работ
    REPAIR("CORRECTIVE_MAINTENANCE");                    // Упрощенное значение для ремонтных работ

    private final String persistedValue;

    WorkType(String persistedValue) {
        this.persistedValue = persistedValue;
    }

    public String getPersistedValue() {
        return persistedValue;
    }

    public static WorkType fromValue(String value) {
        if (value == null) {
            return null;
        }

        return Arrays.stream(values())
                .filter(type -> type.name().equalsIgnoreCase(value))
                .findFirst()
                .orElseGet(() -> Arrays.stream(values())
                        .filter(type -> type.persistedValue.equalsIgnoreCase(value))
                        .findFirst()
                        .orElseThrow(() -> new IllegalArgumentException("Unknown work type: " + value)));
    }
}
