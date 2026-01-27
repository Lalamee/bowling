package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationDecisionStatus;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminCabinetService {

    private final UserRepository userRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final RoleRepository roleRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final OwnerProfileRepository ownerProfileRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final AttestationApplicationRepository attestationApplicationRepository;
    private final SupplierReviewRepository supplierReviewRepository;
    private final RequestPartRepository requestPartRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final PersonalWarehouseRepository personalWarehouseRepository;
    private final NotificationService notificationService;
    private final AttestationService attestationService;

    @Transactional(readOnly = true)
    public List<AdminRegistrationApplicationDTO> listRegistrationApplications() {
        return listRegistrationApplications(0, 50);
    }

    @Transactional(readOnly = true)
    public List<AdminRegistrationApplicationDTO> listRegistrationApplications(int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = clampSize(size);
        return userRepository.findAllWithProfiles(PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "registrationDate"))).stream()
                .map(this::mapUserToRegistration)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdminRegistrationApplicationDTO approveRegistration(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        user.setIsActive(true);
        user.setIsVerified(true);
        user.setLastModified(LocalDateTime.now());

        if (user.getMechanicProfile() != null) {
            MechanicProfile profile = user.getMechanicProfile();
            profile.setIsDataVerified(true);
            profile.setVerificationDate(LocalDate.now());
            profile.setUpdatedAt(LocalDate.now());
            ensurePersonalWarehouse(profile);
            mechanicProfileRepository.save(profile);
        }

        if (user.getOwnerProfile() != null) {
            OwnerProfile ownerProfile = user.getOwnerProfile();
            ownerProfile.setIsDataVerified(true);
            ownerProfile.setVerificationDate(LocalDate.now());
            ownerProfileRepository.save(ownerProfile);
        }

        if (user.getManagerProfile() != null) {
            ManagerProfile managerProfile = user.getManagerProfile();
            managerProfile.setIsDataVerified(true);
            managerProfileRepository.save(managerProfile);
        }

        if (user.getAdministratorProfile() != null) {
            user.getAdministratorProfile().setIsDataVerified(true);
        }

        activateStaffRecords(user);
        userRepository.save(user);
        return mapUserToRegistration(user);
    }

    @Transactional
    public AdminRegistrationApplicationDTO rejectRegistration(Long userId, String reason) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        user.setIsActive(false);
        user.setIsVerified(false);
        user.setLastModified(LocalDateTime.now());

        if (user.getMechanicProfile() != null) {
            user.getMechanicProfile().setIsDataVerified(false);
            mechanicProfileRepository.save(user.getMechanicProfile());
        }
        if (user.getOwnerProfile() != null) {
            user.getOwnerProfile().setIsDataVerified(false);
            ownerProfileRepository.save(user.getOwnerProfile());
        }
        if (user.getManagerProfile() != null) {
            user.getManagerProfile().setIsDataVerified(false);
            managerProfileRepository.save(user.getManagerProfile());
        }

        clubStaffRepository.findByUserUserIdAndIsActiveTrue(userId)
                .forEach(staff -> {
                    staff.setIsActive(false);
                    clubStaffRepository.save(staff);
                });

        userRepository.save(user);
        return mapUserToRegistration(user);
    }

    @Transactional
    public AdminRegistrationApplicationDTO updateFreeMechanicAccount(Long userId, AdminAccountUpdateDTO update) {
        if (update == null || update.getAccountTypeName() == null) {
            throw new IllegalArgumentException("Account type is required");
        }

        AccountTypeName target = AccountTypeName.from(update.getAccountTypeName());
        if (!Set.of(AccountTypeName.FREE_MECHANIC_BASIC, AccountTypeName.FREE_MECHANIC_PREMIUM).contains(target)) {
            throw new IllegalArgumentException("Only free mechanic account types can be assigned here");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.getRole() == null || RoleName.from(user.getRole().getName()) != RoleName.MECHANIC) {
            throw new IllegalArgumentException("User is not a mechanic");
        }

        AccountType accountType = accountTypeRepository.findByNameIgnoreCase(target.name())
                .orElseThrow(() -> new IllegalStateException("Account type not configured: " + target.name()));

        user.setAccountType(accountType);
        user.setLastModified(LocalDateTime.now());

        boolean restricted = update.getAccessLevelName() != null && !update.getAccessLevelName().equalsIgnoreCase("PREMIUM");
        if (target == AccountTypeName.FREE_MECHANIC_BASIC || target == AccountTypeName.FREE_MECHANIC_PREMIUM) {
            Optional.ofNullable(user.getMechanicProfile()).ifPresent(profile -> profile.setClubs(new ArrayList<>()));
            clubStaffRepository.findByUserUserId(userId).forEach(staff -> {
                staff.setIsActive(false);
                staff.setInfoAccessRestricted(restricted);
                clubStaffRepository.save(staff);
            });
        } else {
            clubStaffRepository.findByUserUserIdAndIsActiveTrue(userId).forEach(staff -> {
                staff.setInfoAccessRestricted(restricted);
                clubStaffRepository.save(staff);
            });
        }

        userRepository.save(user);
        return mapUserToRegistration(user);
    }

    @Transactional
    public AdminRegistrationApplicationDTO changeMechanicClubLink(Long profileId, MechanicClubLinkRequestDTO request) {
        if (request == null || request.getClubId() == null) {
            throw new IllegalArgumentException("Club id is required");
        }
        MechanicProfile profile = mechanicProfileRepository.findById(profileId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic profile not found"));
        User user = profile.getUser();
        if (user == null) {
            throw new IllegalStateException("Mechanic profile is not bound to a user");
        }

        BowlingClub club = bowlingClubRepository.findById(request.getClubId())
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));
        Long clubId = club.getClubId();

        AccountTypeName accountType = user.getAccountType() != null
                ? AccountTypeName.from(user.getAccountType().getName())
                : AccountTypeName.INDIVIDUAL;
        boolean isFreeMechanic = accountType == AccountTypeName.FREE_MECHANIC_BASIC
                || accountType == AccountTypeName.FREE_MECHANIC_PREMIUM;
        if (isFreeMechanic && request.isAttach()) {
            AccountType targetAccountType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name())
                    .orElseThrow(() -> new IllegalStateException("Account type not configured: " + AccountTypeName.INDIVIDUAL));
            user.setAccountType(targetAccountType);
            user.setLastModified(LocalDateTime.now());
        } else if (isFreeMechanic) {
            throw new IllegalStateException("Free mechanics cannot be detached from clubs through staff links");
        }

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs())
                .map(ArrayList::new)
                .orElseGet(ArrayList::new);
        if (request.isAttach()) {
            if (clubs.stream().noneMatch(c -> Objects.equals(c.getClubId(), clubId))) {
                clubs.add(club);
                profile.setClubs(clubs);
            }
            upsertStaff(user, club);
            if (isFreeMechanic) {
                clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, user).ifPresent(staff -> {
                    staff.setInfoAccessRestricted(false);
                    staff.setIsActive(true);
                    clubStaffRepository.save(staff);
                });
            }
        } else {
            List<BowlingClub> updatedClubs = clubs.stream()
                    .filter(c -> !Objects.equals(c.getClubId(), clubId))
                    .collect(Collectors.toCollection(ArrayList::new));
            profile.setClubs(updatedClubs);
            clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, user).ifPresent(staff -> {
                staff.setIsActive(false);
                clubStaffRepository.save(staff);
            });
        }

        mechanicProfileRepository.save(profile);
        return mapUserToRegistration(userRepository.save(user));
    }

    @Transactional
    public AdminRegistrationApplicationDTO assignFreeMechanicToClub(Long userId, FreeMechanicClubAssignRequestDTO request) {
        if (request == null || request.getClubId() == null) {
            throw new IllegalArgumentException("Club id is required");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Role userRole = user.getRole();
        if (userRole == null) {
            Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name())
                    .orElseThrow(() -> new IllegalStateException("Mechanic role not configured"));
            user.setRole(mechanicRole);
            userRole = mechanicRole;
        }
        if (RoleName.from(userRole.getName()) != RoleName.MECHANIC) {
            throw new IllegalArgumentException("User is not a mechanic");
        }

        MechanicProfile profile = user.getMechanicProfile();
        if (profile == null) {
            List<MechanicProfile> profiles = mechanicProfileRepository.findAllByUser_UserIdOrderByProfileIdDesc(userId);
            if (profiles.isEmpty()) {
                throw new IllegalStateException("Mechanic profile not found");
            }
            profile = profiles.get(0);
        }

        BowlingClub club = bowlingClubRepository.findById(request.getClubId())
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        AccountType currentAccountType = user.getAccountType();
        String rawAccountType = currentAccountType != null ? currentAccountType.getName() : null;
        boolean isFreeMechanic = rawAccountType != null && rawAccountType.toUpperCase().contains("FREE_MECHANIC");
        if (currentAccountType == null || isFreeMechanic) {
            AccountType targetAccountType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.INDIVIDUAL.name())
                    .orElseThrow(() -> new IllegalStateException("Account type not configured: " + AccountTypeName.INDIVIDUAL));
            user.setAccountType(targetAccountType);
            user.setLastModified(LocalDateTime.now());
        }

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs())
                .map(ArrayList::new)
                .orElseGet(ArrayList::new);
        if (clubs.stream().noneMatch(c -> Objects.equals(c.getClubId(), club.getClubId()))) {
            clubs.add(club);
        }
        profile.setClubs(clubs);
        upsertStaff(user, club);
        clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, user).ifPresent(staff -> {
            staff.setInfoAccessRestricted(false);
            staff.setIsActive(true);
            clubStaffRepository.save(staff);
        });
        ensurePersonalWarehouse(profile);
        profile.setUpdatedAt(LocalDate.now());

        mechanicProfileRepository.save(profile);
        userRepository.save(user);
        log.info("Assigned free mechanic user {} to club {}", userId, club.getClubId());
        return mapUserToRegistration(user);
    }

    @Transactional(readOnly = true)
    public List<AttestationApplicationDTO> listAttestationApplications() {
        return attestationApplicationRepository.findAllByOrderBySubmittedAtDesc().stream()
                .map(this::toAttestationDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AttestationApplicationDTO decideAttestation(Long applicationId, AttestationDecisionDTO decision) {
        return attestationService.updateStatus(applicationId, decision);
    }

    @Transactional(readOnly = true)
    public List<AdminComplaintDTO> listSupplierComplaints() {
        return supplierReviewRepository.findAll().stream()
                .filter(review -> Boolean.TRUE.equals(review.getIsComplaint()))
                .map(this::toComplaintDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdminComplaintDTO updateComplaintStatus(Long reviewId, SupplierComplaintStatus status, Boolean resolved, String notes) {
        SupplierReview review = supplierReviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("Complaint not found"));

        if (status != null) {
            review.setComplaintStatus(status);
        }
        if (resolved != null) {
            review.setComplaintResolved(resolved);
        }
        if (notes != null) {
            review.setResolutionNotes(notes);
        }

        supplierReviewRepository.save(review);
        return toComplaintDto(review);
    }

    @Transactional(readOnly = true)
    public List<AdminHelpRequestDTO> listHelpRequests() {
        List<RequestPart> parts = requestPartRepository.findAll();
        return parts.stream()
                .filter(part -> Boolean.TRUE.equals(part.getHelpRequested()))
                .map(this::toHelpDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AdminMechanicStatusChangeDTO> listMechanicStatusChanges() {
        return clubStaffRepository.findAll().stream()
                .filter(staff -> staff.getUser() != null && staff.getUser().getRole() != null
                        && RoleName.from(staff.getUser().getRole().getName()) == RoleName.MECHANIC)
                .map(this::toStatusChangeDto)
                .filter(dto -> Boolean.FALSE.equals(dto.getIsActive()) || Boolean.TRUE.equals(dto.getInfoAccessRestricted()))
                .collect(Collectors.toList());
    }

    @Transactional
    public AdminMechanicStatusChangeDTO updateMechanicStaffStatus(Long staffId, AdminStaffStatusUpdateDTO update) {
        ClubStaff staff = clubStaffRepository.findById(staffId)
                .orElseThrow(() -> new IllegalArgumentException("Staff record not found"));
        if (update.getActive() != null) {
            staff.setIsActive(update.getActive());
        }
        if (update.getInfoAccessRestricted() != null) {
            staff.setInfoAccessRestricted(update.getInfoAccessRestricted());
        }
        return toStatusChangeDto(clubStaffRepository.save(staff));
    }

    @Transactional
    public AdminRegistrationApplicationDTO convertMechanicAccount(Long userId, AdminMechanicAccountChangeDTO change) {
        if (change == null || change.getAccountTypeName() == null) {
            throw new IllegalArgumentException("Account type is required");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (user.getRole() == null || RoleName.from(user.getRole().getName()) != RoleName.MECHANIC) {
            throw new IllegalArgumentException("User is not a mechanic");
        }

        AccountTypeName target = AccountTypeName.from(change.getAccountTypeName());
        AccountType accountType = accountTypeRepository.findByNameIgnoreCase(target.name())
                .orElseThrow(() -> new IllegalStateException("Account type not configured: " + target.name()));

        user.setAccountType(accountType);
        user.setLastModified(LocalDateTime.now());

        boolean restricted = isRestricted(change.getAccessLevelName());
        if (target == AccountTypeName.FREE_MECHANIC_BASIC || target == AccountTypeName.FREE_MECHANIC_PREMIUM) {
            Optional.ofNullable(user.getMechanicProfile()).ifPresent(profile -> profile.setClubs(new ArrayList<>()));
            clubStaffRepository.findByUserUserId(userId).forEach(staff -> {
                staff.setIsActive(false);
                staff.setInfoAccessRestricted(true);
                clubStaffRepository.save(staff);
            });
            ensurePersonalWarehouse(user.getMechanicProfile());
        } else {
            if (Boolean.TRUE.equals(change.getAttachToClub())) {
                if (change.getClubId() == null) {
                    throw new IllegalArgumentException("Club id is required when attaching mechanic to club account");
                }
                BowlingClub club = bowlingClubRepository.findById(change.getClubId())
                        .orElseThrow(() -> new IllegalArgumentException("Club not found"));
                if (user.getMechanicProfile() != null) {
                    List<BowlingClub> clubs = Optional.ofNullable(user.getMechanicProfile().getClubs())
                            .map(ArrayList::new)
                            .orElseGet(ArrayList::new);
                    if (clubs.stream().noneMatch(c -> Objects.equals(c.getClubId(), club.getClubId()))) {
                        clubs.add(club);
                        user.getMechanicProfile().setClubs(clubs);
                    }
                }
                upsertStaff(user, club);
            }
            clubStaffRepository.findByUserUserId(userId).forEach(staff -> {
                staff.setInfoAccessRestricted(restricted);
                clubStaffRepository.save(staff);
            });
        }
        userRepository.save(user);
        return mapUserToRegistration(user);
    }

    @Transactional(readOnly = true)
    public List<AdminAppealDTO> listAdministrativeAppeals() {
        return notificationService.getNotificationsForRole(RoleName.ADMIN).stream()
                .map(this::toAppealDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public NotificationEvent replyToAppeal(String appealId, AdminAppealReplyDTO request) {
        if (request == null || request.getMessage() == null || request.getMessage().isBlank()) {
            throw new IllegalArgumentException("Ответ обязателен");
        }
        UUID id;
        try {
            id = UUID.fromString(appealId);
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Некорректный идентификатор обращения");
        }

        NotificationEvent appeal = notificationService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Обращение не найдено"));

        String payload = "Ответ на обращение " + appeal.getId();
        if (appeal.getClubId() != null) {
            return notificationService.notifyAdminResponse(appeal.getClubId(), request.getMessage(), payload);
        }
        if (appeal.getMechanicId() != null) {
            return notificationService.notifyAdminResponseToMechanic(appeal.getMechanicId(), request.getMessage(), payload);
        }

        throw new IllegalArgumentException("Обращение не связано с клубом или механиком");
    }

    private AdminHelpRequestDTO toHelpDto(RequestPart part) {
        MaintenanceRequest request = part.getRequest();
        return AdminHelpRequestDTO.builder()
                .partId(part.getPartId())
                .requestId(request != null ? request.getRequestId() : null)
                .mechanicProfileId(request != null && request.getMechanic() != null ? request.getMechanic().getProfileId() : null)
                .clubId(request != null && request.getClub() != null ? request.getClub().getClubId() : null)
                .laneNumber(request != null ? request.getLaneNumber() : null)
                .helpRequested(part.getHelpRequested())
                .partStatus(part.getStatus() != null ? part.getStatus().name() : null)
                .managerNotes(request != null ? request.getManagerNotes() : null)
                .build();
    }

    private AdminMechanicStatusChangeDTO toStatusChangeDto(ClubStaff staff) {
        User user = staff.getUser();
        MechanicProfile profile = user != null ? user.getMechanicProfile() : null;
        BowlingClub club = staff.getClub();
        return AdminMechanicStatusChangeDTO.builder()
                .staffId(staff.getStaffId())
                .userId(user != null ? user.getUserId() : null)
                .mechanicProfileId(profile != null ? profile.getProfileId() : null)
                .clubId(club != null ? club.getClubId() : null)
                .clubName(club != null ? club.getName() : null)
                .role(staff.getRole() != null ? staff.getRole().getName() : null)
                .isActive(staff.getIsActive())
                .infoAccessRestricted(staff.getInfoAccessRestricted())
                .build();
    }

    private AdminAppealDTO toAppealDto(NotificationEvent event) {
        return AdminAppealDTO.builder()
                .id(event.getId() != null ? event.getId().toString() : null)
                .type(event.getType() != null ? event.getType().name() : null)
                .message(event.getMessage())
                .requestId(event.getRequestId())
                .mechanicId(event.getMechanicId())
                .clubId(event.getClubId())
                .partIds(event.getPartIds())
                .payload(event.getPayload())
                .createdAt(event.getCreatedAt())
                .build();
    }

    private AdminComplaintDTO toComplaintDto(SupplierReview review) {
        return AdminComplaintDTO.builder()
                .reviewId(review.getReviewId())
                .supplierId(review.getSupplierId())
                .clubId(review.getClubId())
                .userId(review.getUserId())
                .complaintStatus(review.getComplaintStatus() != null ? review.getComplaintStatus().name() : null)
                .complaintResolved(review.getComplaintResolved())
                .rating(review.getRating())
                .comment(review.getComment())
                .complaintTitle(review.getComplaintTitle())
                .resolutionNotes(review.getResolutionNotes())
                .build();
    }

    private AttestationApplicationDTO toAttestationDto(AttestationApplication application) {
        User user = application.getUser();
        MechanicProfile profile = application.getMechanicProfile();
        if (user == null && profile != null) {
            user = profile.getUser();
        }
        String mechanicName = null;
        if (profile != null && profile.getFullName() != null && !profile.getFullName().isBlank()) {
            mechanicName = profile.getFullName().trim();
        } else if (user != null) {
            mechanicName = user.getFullName();
        }
        String mechanicPhone = user != null ? user.getPhone() : null;
        return AttestationApplicationDTO.builder()
                .id(application.getApplicationId())
                .userId(user != null ? user.getUserId() : null)
                .mechanicProfileId(profile != null ? profile.getProfileId() : null)
                .mechanicName(mechanicName)
                .mechanicPhone(mechanicPhone)
                .status(AttestationDecisionStatus.fromEntity(application.getStatus()))
                .comment(application.getComment())
                .requestedGrade(application.getRequestedGrade())
                .clubId(application.getClub() != null ? application.getClub().getClubId() : null)
                .submittedAt(application.getSubmittedAt())
                .updatedAt(application.getUpdatedAt())
                .build();
    }

    private AdminRegistrationApplicationDTO mapUserToRegistration(User user) {
        String profileType = resolveProfileType(user);
        Long profileId = resolveProfileId(user);
        BowlingClub club = resolvePrimaryClub(user);
        return AdminRegistrationApplicationDTO.builder()
                .userId(user.getUserId())
                .profileId(profileId)
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .role(user.getRole() != null ? user.getRole().getName() : null)
                .accountType(user.getAccountType() != null ? user.getAccountType().getName() : null)
                .profileType(profileType)
                .isActive(user.getIsActive())
                .isVerified(user.getIsVerified())
                .isProfileVerified(resolveProfileVerification(user))
                .clubId(club != null ? club.getClubId() : null)
                .clubName(club != null ? club.getName() : null)
                .submittedAt(user.getRegistrationDate() != null ? user.getRegistrationDate().toString() : null)
                .build();
    }

    private String resolveProfileType(User user) {
        if (user.getMechanicProfile() != null) {
            return "MECHANIC";
        }
        if (user.getOwnerProfile() != null) {
            return "OWNER";
        }
        if (user.getManagerProfile() != null) {
            return "MANAGER";
        }
        if (user.getAdministratorProfile() != null) {
            return "ADMIN";
        }
        return null;
    }

    private Long resolveProfileId(User user) {
        if (user.getMechanicProfile() != null) {
            return user.getMechanicProfile().getProfileId();
        }
        if (user.getOwnerProfile() != null) {
            return user.getOwnerProfile().getOwnerId();
        }
        if (user.getManagerProfile() != null) {
            return user.getManagerProfile().getManagerId();
        }
        if (user.getAdministratorProfile() != null) {
            return user.getAdministratorProfile().getAdministratorId();
        }
        return null;
    }

    private boolean resolveProfileVerification(User user) {
        if (user.getMechanicProfile() != null) {
            return Boolean.TRUE.equals(user.getMechanicProfile().getIsDataVerified());
        }
        if (user.getOwnerProfile() != null) {
            return Boolean.TRUE.equals(user.getOwnerProfile().getIsDataVerified());
        }
        if (user.getManagerProfile() != null) {
            return Boolean.TRUE.equals(user.getManagerProfile().getIsDataVerified());
        }
        if (user.getAdministratorProfile() != null) {
            return Boolean.TRUE.equals(user.getAdministratorProfile().getIsDataVerified());
        }
        return false;
    }

    private int clampSize(int size) {
        if (size <= 0) {
            return 50;
        }
        return Math.min(size, 200);
    }

    private BowlingClub resolvePrimaryClub(User user) {
        if (user.getMechanicProfile() != null && user.getMechanicProfile().getClubs() != null
                && !user.getMechanicProfile().getClubs().isEmpty()) {
            return user.getMechanicProfile().getClubs().get(0);
        }
        if (user.getManagerProfile() != null) {
            return user.getManagerProfile().getClub();
        }
        if (user.getOwnerProfile() != null && user.getOwnerProfile().getClubs() != null
                && !user.getOwnerProfile().getClubs().isEmpty()) {
            return user.getOwnerProfile().getClubs().get(0);
        }
        return null;
    }

    private boolean isRestricted(String accessLevelName) {
        return accessLevelName != null && !accessLevelName.equalsIgnoreCase("PREMIUM");
    }

    private void ensurePersonalWarehouse(MechanicProfile profile) {
        if (profile == null || profile.getProfileId() == null) {
            return;
        }
        List<PersonalWarehouse> existing = personalWarehouseRepository
                .findByMechanicProfile_ProfileIdAndIsActiveTrue(profile.getProfileId());
        if (!existing.isEmpty()) {
            return;
        }

        String ownerName = profile.getFullName() != null ? profile.getFullName() : "механика";
        PersonalWarehouse warehouse = PersonalWarehouse.builder()
                .mechanicProfile(profile)
                .name("Личный zip-склад " + ownerName)
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        personalWarehouseRepository.save(warehouse);
    }

    private void activateStaffRecords(User user) {
        if (user == null) {
            return;
        }
        clubStaffRepository.findByUserUserIdAndIsActiveTrue(user.getUserId())
                .forEach(staff -> {
                    staff.setIsActive(true);
                    clubStaffRepository.save(staff);
                });
    }

    private void upsertStaff(User user, BowlingClub club) {
        if (user == null || club == null) {
            return;
        }
        Role resolvedRole = user.getRole() != null
                ? user.getRole()
                : roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name()).orElse(null);
        Role roleToApply = resolvedRole;

        ClubStaff staff = clubStaffRepository.findFirstByClubAndUserOrderByStaffIdAsc(club, user)
                .orElseGet(() -> ClubStaff.builder()
                        .club(club)
                        .user(user)
                        .assignedAt(LocalDateTime.now())
                        .isActive(true)
                        .role(roleToApply)
                        .build());
        staff.setRole(roleToApply);
        staff.setIsActive(true);
        clubStaffRepository.save(staff);
    }
}
