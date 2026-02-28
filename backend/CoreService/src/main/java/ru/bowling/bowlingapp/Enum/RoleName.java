package ru.bowling.bowlingapp.Enum;

public enum RoleName {
    ADMIN,
    MECHANIC,
    HEAD_MECHANIC,
    CLUB_OWNER;

    public static RoleName from(String rawName) {
        if (rawName == null) {
            throw new IllegalArgumentException("Роль пользователя обязательна");
        }
        try {
            return RoleName.valueOf(rawName.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Неизвестная роль: " + rawName);
        }
    }
}
