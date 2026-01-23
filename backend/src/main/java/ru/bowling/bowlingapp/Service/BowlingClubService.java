package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.ClubCreateDTO;
import ru.bowling.bowlingapp.DTO.ClubSummaryDTO;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BowlingClubService {

    private final BowlingClubRepository bowlingClubRepository;

    @Transactional(readOnly = true)
    public List<ClubSummaryDTO> getAllClubs() {
        return bowlingClubRepository.findAll()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ClubSummaryDTO createClub(ClubCreateDTO request) {
        BowlingClub club = BowlingClub.builder()
                .name(request.getName().trim())
                .address(request.getAddress().trim())
                .lanesCount(request.getLanesCount())
                .contactPhone(trim(request.getContactPhone()))
                .contactEmail(trim(request.getContactEmail()))
                .isActive(true)
                .isVerified(true)
                .verificationDate(LocalDate.now())
                .build();

        BowlingClub saved = bowlingClubRepository.save(club);
        return toDto(saved);
    }

    private ClubSummaryDTO toDto(BowlingClub club) {
        return ClubSummaryDTO.builder()
                .id(club.getClubId())
                .name(club.getName())
                .address(club.getAddress())
                .lanesCount(club.getLanesCount())
                .contactPhone(club.getContactPhone())
                .contactEmail(club.getContactEmail())
                .build();
    }

    private String trim(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
