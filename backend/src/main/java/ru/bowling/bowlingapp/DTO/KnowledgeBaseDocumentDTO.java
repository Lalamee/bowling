package ru.bowling.bowlingapp.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class KnowledgeBaseDocumentDTO {

    private Long documentId;
    private Long clubId;
    private String clubName;
    private String title;
    private String description;
    private String documentType;
    private String manufacturer;
    private String equipmentModel;
    private String language;
    private String fileName;
    private Long fileSize;
    private LocalDateTime uploadDate;
    private String downloadUrl;
}
