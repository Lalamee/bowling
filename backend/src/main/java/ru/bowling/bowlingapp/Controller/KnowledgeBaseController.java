package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.bowling.bowlingapp.DTO.KnowledgeBaseDocumentDTO;
import ru.bowling.bowlingapp.Security.UserPrincipal;
import ru.bowling.bowlingapp.Service.KnowledgeBaseService;

import java.util.List;

@RestController
@RequestMapping("/api/knowledge-base")
@RequiredArgsConstructor
public class KnowledgeBaseController {

    private final KnowledgeBaseService knowledgeBaseService;

    @GetMapping("/documents")
    public List<KnowledgeBaseDocumentDTO> getDocuments(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        return knowledgeBaseService.getDocumentsForUser(userPrincipal.getId());
    }

    @GetMapping("/documents/{documentId}/content")
    public ResponseEntity<byte[]> getDocumentContent(
            @PathVariable Long documentId,
            @AuthenticationPrincipal UserPrincipal userPrincipal
    ) {
        KnowledgeBaseService.DocumentContent documentContent = knowledgeBaseService
                .getDocumentContent(documentId, userPrincipal.getId());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + documentContent.fileName() + "\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(documentContent.data());
    }
}
