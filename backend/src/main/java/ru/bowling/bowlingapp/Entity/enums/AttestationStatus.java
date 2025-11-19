package ru.bowling.bowlingapp.Entity.enums;

import java.util.Arrays;

public enum AttestationStatus {
    NEW,
    IN_REVIEW,
    APPROVED,
    REJECTED;

    public static AttestationStatus fromCode(String value) {
        if (value == null) {
            return null;
        }
        return Arrays.stream(values())
                .filter(status -> status.name().equalsIgnoreCase(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown attestation status: " + value));
    }
}
