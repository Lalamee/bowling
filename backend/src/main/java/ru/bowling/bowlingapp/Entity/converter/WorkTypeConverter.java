package ru.bowling.bowlingapp.Entity.converter;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import ru.bowling.bowlingapp.Entity.enums.WorkType;

@Converter(autoApply = true)
public class WorkTypeConverter implements AttributeConverter<WorkType, String> {
    @Override
    public String convertToDatabaseColumn(WorkType attribute) {
        if (attribute == null) {
            return null;
        }
        return attribute.getPersistedValue();
    }

    @Override
    public WorkType convertToEntityAttribute(String dbData) {
        return WorkType.fromValue(dbData);
    }
}
