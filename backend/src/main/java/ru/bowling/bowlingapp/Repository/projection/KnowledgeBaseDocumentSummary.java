package ru.bowling.bowlingapp.Repository.projection;

import java.time.LocalDateTime;

public interface KnowledgeBaseDocumentSummary {

    Long getDocumentId();

    Long getClubId();

    String getClubName();

    String getTitle();

    String getDescription();

    String getDocumentType();

    String getManufacturer();

    String getEquipmentModel();

    String getLanguage();

    String getFileName();

    Number getFileSize();

    LocalDateTime getUploadDate();
}
