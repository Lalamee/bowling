package ru.bowling.bowlingapp.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class KnowledgeBaseDocumentCreateDTO {

    @NotNull
    private Long clubId;

    @NotBlank
    private String title;

    private String description;

    private String documentType;

    private String manufacturer;

    private String equipmentModel;

    private String language;

    private String accessLevel;

    private String fileName;

    @NotBlank
    private String fileBase64;
}
