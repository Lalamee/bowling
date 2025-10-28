package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ru.bowling.bowlingapp.Entity.TechnicalDocument;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentContent;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentSummary;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface TechnicalDocumentRepository extends JpaRepository<TechnicalDocument, Long> {

    @Query(value = """
            SELECT td.document_id AS documentId,
                   td.club_id AS clubId,
                   club.name AS clubName,
                   td.title AS title,
                   td.description AS description,
                   type.name AS documentType,
                   manufacturer.name AS manufacturerName,
                   td.equipment_model AS equipmentModel,
                   td.language AS language,
                   td.file_name AS fileName,
                   OCTET_LENGTH(td.file_data) AS fileSize,
                   td.upload_date AS uploadDate
            FROM technical_documents td
            JOIN bowling_clubs club ON club.club_id = td.club_id
            LEFT JOIN document_type type ON type.document_type_id = td.document_type_id
            LEFT JOIN manufacturer manufacturer ON manufacturer.manufacturer_id = td.manufacturer_id
            ORDER BY td.upload_date DESC, td.document_id DESC
            """, nativeQuery = true)
    List<KnowledgeBaseDocumentSummary> findAllSummaries();

    @Query(value = """
            SELECT td.document_id AS documentId,
                   td.club_id AS clubId,
                   club.name AS clubName,
                   td.title AS title,
                   td.description AS description,
                   type.name AS documentType,
                   manufacturer.name AS manufacturerName,
                   td.equipment_model AS equipmentModel,
                   td.language AS language,
                   td.file_name AS fileName,
                   OCTET_LENGTH(td.file_data) AS fileSize,
                   td.upload_date AS uploadDate
            FROM technical_documents td
            JOIN bowling_clubs club ON club.club_id = td.club_id
            LEFT JOIN document_type type ON type.document_type_id = td.document_type_id
            LEFT JOIN manufacturer manufacturer ON manufacturer.manufacturer_id = td.manufacturer_id
            WHERE td.club_id IN (:clubIds)
            ORDER BY td.upload_date DESC, td.document_id DESC
            """, nativeQuery = true)
    List<KnowledgeBaseDocumentSummary> findSummariesByClubIds(@Param("clubIds") Collection<Long> clubIds);

    @Query(value = """
            SELECT td.document_id AS documentId,
                   td.club_id AS clubId,
                   td.title AS title,
                   td.file_name AS fileName,
                   td.file_data AS fileData,
                   OCTET_LENGTH(td.file_data) AS fileSize
            FROM technical_documents td
            WHERE td.document_id = :documentId
            """, nativeQuery = true)
    Optional<KnowledgeBaseDocumentContent> findDocumentContentById(@Param("documentId") Long documentId);
}
