package ru.bowling.bowlingapp.Entity.enums;

import java.util.Arrays;

public enum AttestationStatus {
    PENDING,
    APPROVED,
    REJECTED;

    public static AttestationStatus fromCode(String value) {
        if (value == null) {
            return null;
        }
        return Arrays.stream(values())
                .filter(status -> status.name().equalsIgnoreCase(value)
                        || (status == PENDING && ("NEW".equalsIgnoreCase(value) || "IN_REVIEW".equalsIgnoreCase(value))))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown attestation status: " + value));
    }
}
