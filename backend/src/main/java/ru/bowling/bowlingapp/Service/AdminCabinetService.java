package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.SupplierComplaintStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
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

    @Transactional(readOnly = true)
    public List<AdminRegistrationApplicationDTO> listRegistrationApplications() {
        return userRepository.findAll().stream()
                .map(this::mapUserToRegistration)
                .sorted(Comparator.comparing(AdminRegistrationApplicationDTO::getSubmittedAt, Comparator.nullsLast(String::compareTo)))
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
        clubStaffRepository.findByUserUserIdAndIsActiveTrue(userId).forEach(staff -> {
            staff.setInfoAccessRestricted(restricted);
            clubStaffRepository.save(staff);
        });

        userRepository.save(user);
        return mapUserToRegistration(user);
    }

    @Transactional
    public AdminRegistrationApplicationDTO changeMechanicClubLink(Long profileId, MechanicClubLinkRequestDTO request) {
        MechanicProfile profile = mechanicProfileRepository.findById(profileId)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic profile not found"));
        User user = profile.getUser();
        if (user == null) {
            throw new IllegalStateException("Mechanic profile is not bound to a user");
        }

        BowlingClub club = bowlingClubRepository.findById(request.getClubId())
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));
        Long clubId = club.getClubId();

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs()).orElseGet(ArrayList::new);
        if (request.isAttach()) {
            if (clubs.stream().noneMatch(c -> Objects.equals(c.getClubId(), clubId))) {
                clubs.add(club);
                profile.setClubs(clubs);
            }
            upsertStaff(user, club);
        } else {
            profile.setClubs(clubs.stream()
                    .filter(c -> !Objects.equals(c.getClubId(), clubId))
                    .toList());
            clubStaffRepository.findByClubAndUser(club, user).ifPresent(staff -> {
                staff.setIsActive(false);
                clubStaffRepository.save(staff);
            });
        }

        mechanicProfileRepository.save(profile);
        return mapUserToRegistration(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public List<AttestationApplicationDTO> listAttestationApplications() {
        return attestationApplicationRepository.findAllByOrderBySubmittedAtDesc().stream()
                .map(this::toAttestationDto)
                .collect(Collectors.toList());
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
        return AttestationApplicationDTO.builder()
                .id(application.getApplicationId())
                .userId(application.getUser() != null ? application.getUser().getUserId() : null)
                .mechanicProfileId(application.getMechanicProfile() != null ? application.getMechanicProfile().getProfileId() : null)
                .status(application.getStatus())
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
        Role role = user.getRole();
        if (role == null) {
            role = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name())
                    .orElse(null);
        }

        ClubStaff staff = clubStaffRepository.findByClubAndUser(club, user)
                .orElseGet(() -> ClubStaff.builder()
                        .club(club)
                        .user(user)
                        .assignedAt(LocalDateTime.now())
                        .isActive(true)
                        .role(role)
                        .build());
        staff.setRole(role);
        staff.setIsActive(true);
        clubStaffRepository.save(staff);
    }
}
