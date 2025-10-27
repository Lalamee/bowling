package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.GlobalSearchResponseDTO;
import ru.bowling.bowlingapp.DTO.PartDto;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.MaintenanceRequest;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.ManagerProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Entity.WorkLog;
import ru.bowling.bowlingapp.Entity.enums.MaintenanceRequestStatus;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.MaintenanceRequestRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.OwnerProfileRepository;
import ru.bowling.bowlingapp.Repository.ManagerProfileRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Repository.WorkLogRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GlobalSearchService {

    private static final int FETCH_MULTIPLIER = 4;

    private final InventoryService inventoryService;
    private final UserRepository userRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final OwnerProfileRepository ownerProfileRepository;
    private final MaintenanceRequestRepository maintenanceRequestRepository;
    private final WorkLogRepository workLogRepository;
    private final BowlingClubRepository bowlingClubRepository;

    @Transactional(readOnly = true)
    public GlobalSearchResponseDTO search(String rawQuery, int limit, Long userId) {
        String normalizedQuery = rawQuery != null ? rawQuery.trim() : "";
        String loweredQuery = normalizedQuery.toLowerCase(Locale.ROOT);
        boolean hasQuery = !loweredQuery.isEmpty();

        User user = userRepository.findById(userId)
                .orElse(null);

        String roleName = user != null && user.getRole() != null && user.getRole().getName() != null
                ? user.getRole().getName().trim().toUpperCase(Locale.ROOT)
                : "";

        MechanicProfile mechanicProfile = mechanicProfileRepository.findByUser_UserId(userId).orElse(null);
        ManagerProfile managerProfile = managerProfileRepository.findByUser_UserId(userId).orElse(null);
        OwnerProfile ownerProfile = ownerProfileRepository.findByUser_UserId(userId).orElse(null);

        List<Long> accessibleClubIds = resolveAccessibleClubIds(roleName, mechanicProfile, managerProfile, ownerProfile);

        List<PartDto> parts = searchParts(normalizedQuery, limit, accessibleClubIds, roleName);
        List<GlobalSearchResponseDTO.MaintenanceRequestResult> requests = searchMaintenanceRequests(loweredQuery, hasQuery, limit, roleName, mechanicProfile, managerProfile, ownerProfile);
        List<GlobalSearchResponseDTO.WorkLogResult> workLogs = searchWorkLogs(loweredQuery, hasQuery, limit, roleName, mechanicProfile, managerProfile, ownerProfile);
        List<GlobalSearchResponseDTO.ClubResult> clubs = searchClubs(loweredQuery, hasQuery, limit, roleName, accessibleClubIds, ownerProfile, managerProfile);

        return GlobalSearchResponseDTO.builder()
                .parts(parts)
                .maintenanceRequests(requests)
                .workLogs(workLogs)
                .clubs(clubs)
                .build();
    }

    private List<PartDto> searchParts(String query, int limit, List<Long> accessibleClubIds, String roleName) {
        Map<Long, PartDto> aggregated = new LinkedHashMap<>();

        if ("ADMIN".equals(roleName) || accessibleClubIds.isEmpty()) {
            inventoryService.searchParts(query, null)
                    .stream()
                    .limit(limit)
                    .forEach(part -> aggregated.putIfAbsent(safeInventoryKey(part), part));
            return new ArrayList<>(aggregated.values());
        }

        for (Long clubId : accessibleClubIds) {
            inventoryService.searchParts(query, clubId)
                    .stream()
                    .filter(part -> part != null)
                    .forEach(part -> aggregated.putIfAbsent(safeInventoryKey(part), part));
            if (aggregated.size() >= limit) {
                break;
            }
        }

        return aggregated.values().stream()
                .limit(limit)
                .collect(Collectors.toList());
    }

    private Long safeInventoryKey(PartDto part) {
        if (part == null) {
            return null;
        }
        if (part.getInventoryId() != null) {
            return part.getInventoryId();
        }
        if (part.getCatalogId() != null) {
            return part.getCatalogId();
        }
        return part.hashCode() & 0xffffffffL;
    }

    private List<GlobalSearchResponseDTO.MaintenanceRequestResult> searchMaintenanceRequests(
            String loweredQuery,
            boolean hasQuery,
            int limit,
            String roleName,
            MechanicProfile mechanicProfile,
            ManagerProfile managerProfile,
            OwnerProfile ownerProfile
    ) {
        List<MaintenanceRequest> pool = new ArrayList<>();

        if ("ADMIN".equals(roleName)) {
            pool.addAll(maintenanceRequestRepository.findAllByOrderByRequestDateDesc());
        } else if ("MECHANIC".equals(roleName) && mechanicProfile != null) {
            pool.addAll(maintenanceRequestRepository.findByMechanic_ProfileId(mechanicProfile.getProfileId()));
        } else if ("HEAD_MECHANIC".equals(roleName) && managerProfile != null && managerProfile.getClub() != null) {
            pool.addAll(maintenanceRequestRepository.findByClubClubIdOrderByRequestDateDesc(managerProfile.getClub().getClubId()));
        } else if ("CLUB_OWNER".equals(roleName) && ownerProfile != null && ownerProfile.getClubs() != null) {
            for (BowlingClub club : ownerProfile.getClubs()) {
                if (club != null && club.getClubId() != null) {
                    pool.addAll(maintenanceRequestRepository.findByClubClubIdOrderByRequestDateDesc(club.getClubId()));
                }
            }
        } else if (mechanicProfile != null) {
            pool.addAll(maintenanceRequestRepository.findByMechanic_ProfileId(mechanicProfile.getProfileId()));
        }

        Comparator<MaintenanceRequest> comparator = Comparator
                .comparing(this::safeRequestDate, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(MaintenanceRequest::getRequestId, Comparator.nullsLast(Comparator.naturalOrder()));

        return pool.stream()
                .filter(Objects::nonNull)
                .sorted(comparator)
                .filter(req -> hasQuery ? matchesMaintenanceRequest(req, loweredQuery) : true)
                .distinct()
                .limit(limit)
                .map(this::toMaintenanceResult)
                .collect(Collectors.toList());
    }

    private LocalDateTime safeRequestDate(MaintenanceRequest request) {
        return request != null ? request.getRequestDate() : null;
    }

    private boolean matchesMaintenanceRequest(MaintenanceRequest request, String loweredQuery) {
        if (loweredQuery.isEmpty()) {
            return true;
        }
        String status = Optional.ofNullable(request.getStatus())
                .map(MaintenanceRequestStatus::name)
                .orElse("");
        String clubName = Optional.ofNullable(request.getClub()).map(BowlingClub::getName).orElse("");
        String mechanicName = Optional.ofNullable(request.getMechanic()).map(MechanicProfile::getFullName).orElse("");
        String lane = request.getLaneNumber() != null ? String.valueOf(request.getLaneNumber()) : "";
        String id = request.getRequestId() != null ? String.valueOf(request.getRequestId()) : "";

        return matchesAny(loweredQuery, status, clubName, mechanicName, lane, id);
    }

    private GlobalSearchResponseDTO.MaintenanceRequestResult toMaintenanceResult(MaintenanceRequest request) {
        BowlingClub club = request.getClub();
        MechanicProfile mechanic = request.getMechanic();
        return GlobalSearchResponseDTO.MaintenanceRequestResult.builder()
                .id(request.getRequestId())
                .status(Optional.ofNullable(request.getStatus()).map(MaintenanceRequestStatus::name).orElse(null))
                .clubName(club != null ? club.getName() : null)
                .laneNumber(request.getLaneNumber())
                .mechanicName(mechanic != null ? mechanic.getFullName() : null)
                .requestedAt(request.getRequestDate())
                .build();
    }

    private List<GlobalSearchResponseDTO.WorkLogResult> searchWorkLogs(
            String loweredQuery,
            boolean hasQuery,
            int limit,
            String roleName,
            MechanicProfile mechanicProfile,
            ManagerProfile managerProfile,
            OwnerProfile ownerProfile
    ) {
        Set<WorkLog> collected = new LinkedHashSet<>();
        int pageSize = Math.max(limit * FETCH_MULTIPLIER, limit);

        if ("ADMIN".equals(roleName)) {
            collected.addAll(workLogRepository.findAllByOrderByCreatedDateDesc(PageRequest.of(0, pageSize)).getContent());
        } else if ("MECHANIC".equals(roleName) && mechanicProfile != null) {
            collected.addAll(workLogRepository.findByMechanicProfileId(mechanicProfile.getProfileId(), PageRequest.of(0, pageSize)).getContent());
        } else if ("HEAD_MECHANIC".equals(roleName) && managerProfile != null && managerProfile.getClub() != null) {
            collected.addAll(workLogRepository.findByClubClubId(managerProfile.getClub().getClubId(), PageRequest.of(0, pageSize)).getContent());
        } else if ("CLUB_OWNER".equals(roleName) && ownerProfile != null && ownerProfile.getClubs() != null) {
            for (BowlingClub club : ownerProfile.getClubs()) {
                if (club != null && club.getClubId() != null) {
                    collected.addAll(workLogRepository.findByClubClubId(club.getClubId(), PageRequest.of(0, pageSize)).getContent());
                }
            }
        } else if (mechanicProfile != null) {
            collected.addAll(workLogRepository.findByMechanicProfileId(mechanicProfile.getProfileId(), PageRequest.of(0, pageSize)).getContent());
        }

        Comparator<WorkLog> comparator = Comparator
                .comparing(this::safeCreatedDate, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(WorkLog::getLogId, Comparator.nullsLast(Comparator.naturalOrder()));

        return collected.stream()
                .filter(Objects::nonNull)
                .sorted(comparator)
                .filter(log -> hasQuery ? matchesWorkLog(log, loweredQuery) : true)
                .limit(limit)
                .map(this::toWorkLogResult)
                .collect(Collectors.toList());
    }

    private LocalDateTime safeCreatedDate(WorkLog log) {
        return log != null ? log.getCreatedDate() : null;
    }

    private boolean matchesWorkLog(WorkLog log, String loweredQuery) {
        if (loweredQuery.isEmpty()) {
            return true;
        }
        String status = Optional.ofNullable(log.getStatus()).map(Enum::name).orElse("");
        String workType = Optional.ofNullable(log.getWorkType()).map(Enum::name).orElse("");
        String clubName = Optional.ofNullable(log.getClub()).map(BowlingClub::getName).orElse("");
        String mechanicName = Optional.ofNullable(log.getMechanic()).map(MechanicProfile::getFullName).orElse("");
        String lane = log.getLaneNumber() != null ? String.valueOf(log.getLaneNumber()) : "";
        String id = log.getLogId() != null ? String.valueOf(log.getLogId()) : "";
        String problem = Optional.ofNullable(log.getProblemDescription()).orElse("");

        return matchesAny(loweredQuery, status, workType, clubName, mechanicName, lane, id, problem);
    }

    private GlobalSearchResponseDTO.WorkLogResult toWorkLogResult(WorkLog log) {
        BowlingClub club = log.getClub();
        MechanicProfile mechanic = log.getMechanic();
        return GlobalSearchResponseDTO.WorkLogResult.builder()
                .id(log.getLogId())
                .status(Optional.ofNullable(log.getStatus()).map(Enum::name).orElse(null))
                .workType(Optional.ofNullable(log.getWorkType()).map(Enum::name).orElse(null))
                .clubName(club != null ? club.getName() : null)
                .laneNumber(log.getLaneNumber())
                .mechanicName(mechanic != null ? mechanic.getFullName() : null)
                .problemDescription(log.getProblemDescription())
                .createdAt(log.getCreatedDate())
                .build();
    }

    private List<GlobalSearchResponseDTO.ClubResult> searchClubs(
            String loweredQuery,
            boolean hasQuery,
            int limit,
            String roleName,
            List<Long> accessibleClubIds,
            OwnerProfile ownerProfile,
            ManagerProfile managerProfile
    ) {
        Set<BowlingClub> clubs = new LinkedHashSet<>();

        if ("ADMIN".equals(roleName)) {
            clubs.addAll(bowlingClubRepository.findAll());
        } else if ("CLUB_OWNER".equals(roleName) && ownerProfile != null && ownerProfile.getClubs() != null) {
            clubs.addAll(ownerProfile.getClubs());
        } else if ("HEAD_MECHANIC".equals(roleName) && managerProfile != null && managerProfile.getClub() != null) {
            clubs.add(managerProfile.getClub());
        } else if (!accessibleClubIds.isEmpty()) {
            for (Long id : accessibleClubIds) {
                bowlingClubRepository.findById(id).ifPresent(clubs::add);
            }
        }

        Comparator<BowlingClub> comparator = Comparator
                .comparing(BowlingClub::getName, Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER))
                .thenComparing(BowlingClub::getClubId, Comparator.nullsLast(Comparator.naturalOrder()));

        return clubs.stream()
                .filter(Objects::nonNull)
                .sorted(comparator)
                .filter(club -> hasQuery ? matchesClub(club, loweredQuery) : true)
                .limit(limit)
                .map(this::toClubResult)
                .collect(Collectors.toList());
    }

    private boolean matchesClub(BowlingClub club, String loweredQuery) {
        if (loweredQuery.isEmpty()) {
            return true;
        }
        String name = Optional.ofNullable(club.getName()).orElse("");
        String address = Optional.ofNullable(club.getAddress()).orElse("");
        String id = club.getClubId() != null ? String.valueOf(club.getClubId()) : "";
        return matchesAny(loweredQuery, name, address, id);
    }

    private GlobalSearchResponseDTO.ClubResult toClubResult(BowlingClub club) {
        return GlobalSearchResponseDTO.ClubResult.builder()
                .id(club.getClubId())
                .name(club.getName())
                .address(club.getAddress())
                .active(club.getIsActive())
                .verified(club.getIsVerified())
                .build();
    }

    private boolean matchesAny(String loweredQuery, String... candidates) {
        for (String candidate : candidates) {
            if (candidate != null && candidate.toLowerCase(Locale.ROOT).contains(loweredQuery)) {
                return true;
            }
        }
        return false;
    }

    private List<Long> resolveAccessibleClubIds(String roleName, MechanicProfile mechanicProfile, ManagerProfile managerProfile, OwnerProfile ownerProfile) {
        Set<Long> ids = new LinkedHashSet<>();
        if (("MECHANIC".equals(roleName) || mechanicProfile != null) && mechanicProfile != null && mechanicProfile.getClubs() != null) {
            mechanicProfile.getClubs().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .forEach(ids::add);
        }
        if (("HEAD_MECHANIC".equals(roleName) || managerProfile != null) && managerProfile != null && managerProfile.getClub() != null) {
            if (managerProfile.getClub().getClubId() != null) {
                ids.add(managerProfile.getClub().getClubId());
            }
        }
        if (("CLUB_OWNER".equals(roleName) || ownerProfile != null) && ownerProfile != null && ownerProfile.getClubs() != null) {
            ownerProfile.getClubs().stream()
                    .map(BowlingClub::getClubId)
                    .filter(Objects::nonNull)
                    .forEach(ids::add);
        }
        return new ArrayList<>(ids);
    }
}
