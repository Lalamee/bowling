package ru.bowling.bowlingapp.Entity.enums;

/**
 * High level attestation decision statuses exposed via API.
 * They map to the persisted {@link AttestationStatus} values that are constrained by the database schema.
 */
public enum AttestationDecisionStatus {
    PENDING,
    APPROVED,
    REJECTED;

    public static AttestationDecisionStatus fromEntity(AttestationStatus status) {
        if (status == null) {
            return null;
        }
        return switch (status) {
            case APPROVED -> APPROVED;
            case REJECTED -> REJECTED;
            case NEW, IN_REVIEW -> PENDING;
        };
    }

    public AttestationStatus toEntityStatus() {
        return switch (this) {
            case PENDING -> AttestationStatus.IN_REVIEW;
            case APPROVED -> AttestationStatus.APPROVED;
            case REJECTED -> AttestationStatus.REJECTED;
        };
    }
}
