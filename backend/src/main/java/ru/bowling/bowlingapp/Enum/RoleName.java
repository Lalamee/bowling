package ru.bowling.bowlingapp.Enum;

public enum RoleName {
    ADMIN,
    MECHANIC,
    HEAD_MECHANIC,
    CLUB_OWNER;

    public static RoleName from(String rawName) {
        if (rawName == null) {
            throw new IllegalArgumentException("Role name is required");
        }
        try {
            return RoleName.valueOf(rawName.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Unsupported role: " + rawName);
        }
    }
}
