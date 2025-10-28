package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ru.bowling.bowlingapp.Entity.TechnicalDocument;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentSummary;

import java.util.Collection;
import java.util.List;

public interface TechnicalDocumentRepository extends JpaRepository<TechnicalDocument, Long> {

    @Query("""
            select td.documentId as documentId,
                   club.clubId as clubId,
                   club.name as clubName,
                   td.title as title,
                   td.description as description,
                   type.name as documentType,
                   manufacturer.name as manufacturerName,
                   td.equipmentModel as equipmentModel,
                   td.language as language,
                   td.fileName as fileName,
                   td.fileSize as fileSize,
                   td.uploadDate as uploadDate
            from TechnicalDocument td
            join td.club club
            left join td.documentType type
            left join td.manufacturer manufacturer
            order by td.uploadDate desc, td.documentId desc
            """)
    List<KnowledgeBaseDocumentSummary> findAllSummaries();

    @Query("""
            select td.documentId as documentId,
                   club.clubId as clubId,
                   club.name as clubName,
                   td.title as title,
                   td.description as description,
                   type.name as documentType,
                   manufacturer.name as manufacturerName,
                   td.equipmentModel as equipmentModel,
                   td.language as language,
                   td.fileName as fileName,
                   td.fileSize as fileSize,
                   td.uploadDate as uploadDate
            from TechnicalDocument td
            join td.club club
            left join td.documentType type
            left join td.manufacturer manufacturer
            where club.clubId in :clubIds
            order by td.uploadDate desc, td.documentId desc
            """)
    List<KnowledgeBaseDocumentSummary> findSummariesByClubIds(@Param("clubIds") Collection<Long> clubIds);
}
