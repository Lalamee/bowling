package ru.bowling.bowlingapp.Repository.projection;

public interface KnowledgeBaseDocumentContent {

    Long getDocumentId();

    Long getClubId();

    String getTitle();

    String getFileName();

    byte[] getFileData();

    Number getFileSize();
}
