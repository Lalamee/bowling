package ru.bowling.bowlingapp.Service;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.KnowledgeBaseDocumentDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.TechnicalDocumentRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentContent;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentSummary;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class KnowledgeBaseService {

    private final TechnicalDocumentRepository technicalDocumentRepository;
    private final UserRepository userRepository;
    private final ClubStaffRepository clubStaffRepository;

    @Transactional(readOnly = true)
    public List<KnowledgeBaseDocumentDTO> getDocumentsForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        List<KnowledgeBaseDocumentSummary> summaries;
        if (isAdmin(user)) {
            summaries = technicalDocumentRepository.findAllSummaries();
        } else {
            Set<Long> clubIds = collectAccessibleClubIds(user);
            if (clubIds.isEmpty()) {
                return List.of();
            }
            summaries = technicalDocumentRepository.findSummariesByClubIds(clubIds);
        }

        return summaries.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DocumentContent getDocumentContent(Long documentId, Long userId) {
        KnowledgeBaseDocumentContent document = technicalDocumentRepository.findDocumentContentById(documentId)
                .orElseThrow(() -> new EntityNotFoundException("Document not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        if (!isAdmin(user)) {
            Long clubId = document.getClubId();
            if (clubId == null || !collectAccessibleClubIds(user).contains(clubId)) {
                throw new AccessDeniedException("Access to the document is denied");
            }
        }

        byte[] data = document.getFileData();
        if (data == null || data.length == 0) {
            throw new EntityNotFoundException("Document file is empty");
        }

        String fileName = Optional.ofNullable(document.getFileName())
                .filter(name -> !name.isBlank())
                .orElseGet(() -> buildDefaultFileName(document));

        long actualSize = data.length;

        return new DocumentContent(data, fileName, actualSize);
    }

    private KnowledgeBaseDocumentDTO mapToDto(KnowledgeBaseDocumentSummary summary) {
        return KnowledgeBaseDocumentDTO.builder()
                .documentId(summary.getDocumentId())
                .clubId(summary.getClubId())
                .clubName(summary.getClubName())
                .title(summary.getTitle())
                .description(summary.getDescription())
                .documentType(summary.getDocumentType())
                .manufacturer(summary.getManufacturer())
                .equipmentModel(summary.getEquipmentModel())
                .language(summary.getLanguage())
                .fileName(summary.getFileName())
                .fileSize(summary.getFileSize())
                .uploadDate(summary.getUploadDate())
                .downloadUrl(buildDownloadUrl(summary.getDocumentId()))
                .build();
    }

    private boolean isAdmin(User user) {
        return Optional.ofNullable(user.getRole())
                .map(Role::getName)
                .map(name -> name.equalsIgnoreCase("ADMIN"))
                .orElse(false);
    }

    private Set<Long> collectAccessibleClubIds(User user) {
        Set<Long> clubIds = new HashSet<>();

        OwnerProfile ownerProfile = user.getOwnerProfile();
        if (ownerProfile != null && ownerProfile.getClubs() != null) {
            ownerProfile.getClubs().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .forEach(clubIds::add);
        }

        MechanicProfile mechanicProfile = user.getMechanicProfile();
        if (mechanicProfile != null && mechanicProfile.getClubs() != null) {
            mechanicProfile.getClubs().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .forEach(clubIds::add);
        }

        ManagerProfile managerProfile = user.getManagerProfile();
        if (managerProfile != null && managerProfile.getClub() != null) {
            Long clubId = managerProfile.getClub().getClubId();
            if (clubId != null) {
                clubIds.add(clubId);
            }
        }

        clubStaffRepository.findByUserUserIdAndIsActiveTrue(user.getUserId())
                .stream()
                .map(ClubStaff::getClub)
                .filter(Objects::nonNull)
                .map(BowlingClub::getClubId)
                .filter(Objects::nonNull)
                .forEach(clubIds::add);

        return clubIds;
    }

    private String buildDownloadUrl(Long documentId) {
        return "/api/knowledge-base/documents/" + documentId + "/content";
    }

    private String buildDefaultFileName(KnowledgeBaseDocumentContent document) {
        String base = Optional.ofNullable(document.getTitle())
                .filter(title -> !title.isBlank())
                .orElse("document");
        return base.replaceAll("\\s+", "_") + ".pdf";
    }

    public record DocumentContent(byte[] data, String fileName, long fileSize) {
    }
}
