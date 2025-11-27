package ru.bowling.bowlingapp.Enum;

public enum AccountTypeName {
    INDIVIDUAL,
    CLUB_OWNER,
    CLUB_MANAGER,
    FREE_MECHANIC_BASIC,
    FREE_MECHANIC_PREMIUM,
    MAIN_ADMIN;

    public static AccountTypeName from(String rawName) {
        if (rawName == null) {
            throw new IllegalArgumentException("Account type name is required");
        }
        try {
            return AccountTypeName.valueOf(rawName.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Unsupported account type: " + rawName);
        }
    }
}
