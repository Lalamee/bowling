package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import ru.bowling.bowlingapp.DTO.AttestationApplicationDTO;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

@Service
@Slf4j
@RequiredArgsConstructor
public class AttestationService {

    private final List<AttestationApplicationDTO> applications = new CopyOnWriteArrayList<>();
    private final AtomicLong sequence = new AtomicLong(1);

    public List<AttestationApplicationDTO> listApplications() {
        return new ArrayList<>(applications);
    }

    public AttestationApplicationDTO submitApplication(AttestationApplicationDTO dto) {
        LocalDateTime now = LocalDateTime.now();
        AttestationApplicationDTO stored = AttestationApplicationDTO.builder()
                .id(sequence.getAndIncrement())
                .userId(dto.getUserId())
                .mechanicProfileId(dto.getMechanicProfileId())
                .clubId(dto.getClubId())
                .requestedGrade(dto.getRequestedGrade())
                .comment(dto.getComment())
                .status(Optional.ofNullable(dto.getStatus()).orElse("NEW"))
                .submittedAt(now)
                .updatedAt(now)
                .build();

        applications.add(stored);
        log.info("Attestation application recorded (stub): {}", stored);
        return stored;
    }

    public AttestationApplicationDTO updateStatus(Long applicationId, String status, String comment) {
        AttestationApplicationDTO current = applications.stream()
                .filter(app -> applicationId.equals(app.getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

        if ("REJECTED".equalsIgnoreCase(status) && (comment == null || comment.isBlank())) {
            throw new IllegalArgumentException("Comment is required when rejecting an application");
        }

        current.setStatus(status);
        current.setComment(comment);
        current.setUpdatedAt(LocalDateTime.now());
        // TODO: заменить на запись в постоянное хранилище, когда модель аттестации будет определена
        return current;
    }
}

