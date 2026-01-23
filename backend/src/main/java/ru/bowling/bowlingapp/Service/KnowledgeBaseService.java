package ru.bowling.bowlingapp.Service;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.KnowledgeBaseDocumentCreateDTO;
import ru.bowling.bowlingapp.DTO.KnowledgeBaseDocumentDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Repository.AccessLevelRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.DocumentTypeRepository;
import ru.bowling.bowlingapp.Repository.ManufacturerRepository;
import ru.bowling.bowlingapp.Repository.TechnicalDocumentRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentContent;
import ru.bowling.bowlingapp.Repository.projection.KnowledgeBaseDocumentSummary;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class KnowledgeBaseService {

    private final TechnicalDocumentRepository technicalDocumentRepository;
    private final UserRepository userRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final DocumentTypeRepository documentTypeRepository;
    private final ManufacturerRepository manufacturerRepository;
    private final AccessLevelRepository accessLevelRepository;

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
                .filter(summary -> hasAccessToDocument(user, summary))
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

        long actualSize = Optional.ofNullable(document.getFileSize())
                .map(Number::longValue)
                .filter(size -> size > 0)
                .orElse((long) data.length);

        return new DocumentContent(data, fileName, actualSize);
    }

    @Transactional
    public KnowledgeBaseDocumentDTO createDocument(KnowledgeBaseDocumentCreateDTO request, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        if (!isAdmin(user)) {
            throw new AccessDeniedException("Only admins can upload documents");
        }

        BowlingClub club = bowlingClubRepository.findById(request.getClubId())
                .orElseThrow(() -> new EntityNotFoundException("Club not found"));

        byte[] fileData = decodeBase64(request.getFileBase64());
        if (fileData.length == 0) {
            throw new IllegalArgumentException("File data is empty");
        }

        String fileName = Optional.ofNullable(request.getFileName())
                .filter(name -> !name.isBlank())
                .orElseGet(() -> buildFileName(request.getTitle()));

        TechnicalDocument document = TechnicalDocument.builder()
                .club(club)
                .title(request.getTitle().trim())
                .description(trim(request.getDescription()))
                .documentType(resolveDocumentType(request.getDocumentType()))
                .manufacturer(resolveManufacturer(request.getManufacturer()))
                .equipmentModel(trim(request.getEquipmentModel()))
                .language(trim(request.getLanguage()))
                .fileName(fileName)
                .fileSize((long) fileData.length)
                .fileData(fileData)
                .uploadDate(LocalDateTime.now())
                .uploadedBy(userId)
                .accessLevel(resolveAccessLevel(request.getAccessLevel()))
                .build();

        TechnicalDocument saved = technicalDocumentRepository.save(document);

        return KnowledgeBaseDocumentDTO.builder()
                .documentId(saved.getDocumentId())
                .clubId(club.getClubId())
                .clubName(club.getName())
                .title(saved.getTitle())
                .description(saved.getDescription())
                .documentType(saved.getDocumentType() != null ? saved.getDocumentType().getName() : null)
                .manufacturer(saved.getManufacturer() != null ? saved.getManufacturer().getName() : null)
                .equipmentModel(saved.getEquipmentModel())
                .language(saved.getLanguage())
                .fileName(saved.getFileName())
                .fileSize(saved.getFileSize())
                .uploadDate(saved.getUploadDate())
                .downloadUrl(buildDownloadUrl(saved.getDocumentId()))
                .accessLevel(saved.getAccessLevel() != null ? saved.getAccessLevel().getName() : null)
                .build();
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
                .fileSize(Optional.ofNullable(summary.getFileSize())
                        .map(Number::longValue)
                        .filter(size -> size > 0)
                        .orElse(null))
                .uploadDate(summary.getUploadDate())
                .downloadUrl(buildDownloadUrl(summary.getDocumentId()))
                .accessLevel(summary.getAccessLevelName())
                .build();
    }

    private boolean isAdmin(User user) {
        return Optional.ofNullable(user.getRole())
                .map(Role::getName)
                .map(name -> name.equalsIgnoreCase("ADMIN"))
                .orElse(false);
    }

    private boolean hasAccessToDocument(User user, KnowledgeBaseDocumentSummary summary) {
        if (hasPremiumKnowledgeAccess(user)) {
            return true;
        }

        String accessLevel = Optional.ofNullable(summary.getAccessLevelName())
                .map(String::trim)
                .orElse("");

        if (accessLevel.isEmpty()) {
            return true;
        }

        String normalized = normalize(accessLevel);
        return !(normalized.contains("premium") || normalized.contains("прем"));
    }

    private boolean hasPremiumKnowledgeAccess(User user) {
        if (isAdmin(user)) {
            return true;
        }

        String normalizedAccountType = Optional.ofNullable(user.getAccountType())
                .map(AccountType::getName)
                .map(this::normalize)
                .orElse("");

        if (normalizedAccountType.contains("premium") || normalizedAccountType.contains("прем")) {
            return true;
        }

        if (isClubMember(user)) {
            return true;
        }

        return false;
    }

    private boolean isClubMember(User user) {
        if (user.getOwnerProfile() != null && user.getOwnerProfile().getClubs() != null
                && !user.getOwnerProfile().getClubs().isEmpty()) {
            return true;
        }

        ManagerProfile managerProfile = user.getManagerProfile();
        if (managerProfile != null && managerProfile.getClub() != null
                && Boolean.TRUE.equals(user.getIsVerified())
                && Boolean.TRUE.equals(managerProfile.getIsDataVerified())) {
            return true;
        }

        return !clubStaffRepository.findByUserUserIdAndIsActiveTrue(user.getUserId()).isEmpty();
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
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

        ManagerProfile managerProfile = user.getManagerProfile();
        if (managerProfile != null && managerProfile.getClub() != null
                && Boolean.TRUE.equals(user.getIsVerified())
                && Boolean.TRUE.equals(managerProfile.getIsDataVerified())
                && clubStaffRepository.existsByClubAndUserAndIsActiveTrue(managerProfile.getClub(), user)) {
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

    private String buildFileName(String title) {
        String base = Optional.ofNullable(title)
                .filter(value -> !value.isBlank())
                .orElse("document");
        return base.replaceAll("\\s+", "_") + ".pdf";
    }

    private String trim(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private byte[] decodeBase64(String raw) {
        String normalized = Optional.ofNullable(raw).orElse("").trim();
        if (normalized.startsWith("data:")) {
            int commaIndex = normalized.indexOf(',');
            if (commaIndex >= 0) {
                normalized = normalized.substring(commaIndex + 1);
            }
        }
        try {
            return Base64.getDecoder().decode(normalized);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid base64 content", e);
        }
    }

    private DocumentType resolveDocumentType(String name) {
        String normalized = trim(name);
        if (normalized == null) {
            return null;
        }
        return documentTypeRepository.findByNameIgnoreCase(normalized)
                .orElseGet(() -> documentTypeRepository.save(DocumentType.builder().name(normalized).build()));
    }

    private Manufacturer resolveManufacturer(String name) {
        String normalized = trim(name);
        if (normalized == null) {
            return null;
        }
        return manufacturerRepository.findByNameIgnoreCase(normalized)
                .orElseGet(() -> manufacturerRepository.save(Manufacturer.builder().name(normalized).build()));
    }

    private AccessLevel resolveAccessLevel(String name) {
        String normalized = trim(name);
        if (normalized == null) {
            return null;
        }
        return accessLevelRepository.findByNameIgnoreCase(normalized)
                .orElseGet(() -> accessLevelRepository.save(AccessLevel.builder().name(normalized).build()));
    }

    public record DocumentContent(byte[] data, String fileName, long fileSize) {
    }
}
