package ru.bowling.bowlingapp.Service;

import java.util.Locale;

public enum InventoryAvailabilityFilter {
    ALL,
    IN_STOCK,
    LOW_STOCK;

    public static InventoryAvailabilityFilter fromString(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return InventoryAvailabilityFilter.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ignored) {
            return null;
        }
    }
}
