package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "technical_documents")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TechnicalDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "document_id")
    private Long documentId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_type_id", nullable = false)
    private DocumentType documentType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manufacturer_id")
    private Manufacturer manufacturer;

    @Column(name = "equipment_model")
    private String equipmentModel;

    @Column(name = "language")
    private String language;

    @Column(name = "file_url", nullable = false)
    private String fileUrl;

    @Column(name = "upload_date", nullable = false)
    private LocalDateTime uploadDate;

    @Column(name = "uploaded_by")
    private Long uploadedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "access_level_id")
    private AccessLevel accessLevel;
}


