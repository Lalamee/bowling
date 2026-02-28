package ru.bowling.bowlingapp.Entity.converter;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;

@Converter(autoApply = true)
public class AttestationStatusConverter implements AttributeConverter<AttestationStatus, String> {

    @Override
    public String convertToDatabaseColumn(AttestationStatus attribute) {
        if (attribute == null) {
            return null;
        }

        return switch (attribute) {
            case PENDING -> "NEW";
            case APPROVED -> AttestationStatus.APPROVED.name();
            case REJECTED -> AttestationStatus.REJECTED.name();
        };
    }

    @Override
    public AttestationStatus convertToEntityAttribute(String dbData) {
        return AttestationStatus.fromCode(dbData);
    }
}
