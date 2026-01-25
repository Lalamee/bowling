package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationRequestDTO;
import ru.bowling.bowlingapp.DTO.FreeMechanicApplicationResponseDTO;
import ru.bowling.bowlingapp.DTO.MechanicApplicationDecisionDTO;
import ru.bowling.bowlingapp.DTO.MechanicCertificationDTO;
import ru.bowling.bowlingapp.DTO.MechanicWorkHistoryDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

@Service
@Slf4j
@RequiredArgsConstructor
public class FreeMechanicApplicationService {

    private static final Pattern RUSSIAN_PHONE_PATTERN = Pattern.compile("^\\+7\\d{10}$");

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final AttestationApplicationRepository attestationApplicationRepository;
    private final PersonalWarehouseRepository personalWarehouseRepository;
    private final BowlingClubRepository bowlingClubRepository;
    private final PasswordEncoder passwordEncoder;
    private final NotificationService notificationService;

    @Transactional
    public FreeMechanicApplicationResponseDTO submitApplication(FreeMechanicApplicationRequestDTO request) {
        validateRequest(request);

        String normalizedPhone = normalizePhone(request.getPhone());
        if (normalizedPhone == null) {
            throw new IllegalArgumentException("Invalid phone format");
        }

        if (userRepository.existsByPhone(normalizedPhone)) {
            throw new IllegalArgumentException("User with this phone already exists");
        }

        Role mechanicRole = roleRepository.findByNameIgnoreCase(RoleName.MECHANIC.name())
                .orElseThrow(() -> new IllegalStateException("MECHANIC role not configured"));

        AccountType accountType = accountTypeRepository.findByNameIgnoreCase(AccountTypeName.FREE_MECHANIC_BASIC.name())
                .orElseThrow(() -> new IllegalStateException("Account type FREE_MECHANIC_BASIC not configured"));

        User user = User.builder()
                .phone(normalizedPhone)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(mechanicRole)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(false)
                .accountType(accountType)
                .build();

        MechanicProfile profile = MechanicProfile.builder()
                .user(user)
                .fullName(request.getFullName())
                .birthDate(request.getBirthDate())
                .educationLevelId(request.getEducationLevelId())
                .educationalInstitution(request.getEducationalInstitution())
                .totalExperienceYears(request.getTotalExperienceYears())
                .bowlingExperienceYears(request.getBowlingExperienceYears())
                .isEntrepreneur(request.getIsEntrepreneur())
                .specializationId(request.getSpecializationId())
                .skills(request.getSkills())
                .advantages(request.getAdvantages())
                .region(request.getRegion())
                .isDataVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .build();
        profile.setClubs(new ArrayList<>());
        applyCertifications(profile, request.getCertifications());
        applyWorkHistory(profile, request.getWorkHistory());
        user.setMechanicProfile(profile);

        userRepository.save(user);
        mechanicProfileRepository.save(profile);

        BowlingClub selectedClub = null;
        if (request.getClubId() != null) {
            selectedClub = bowlingClubRepository.findById(request.getClubId())
                    .orElseThrow(() -> new IllegalArgumentException("Club not found"));
        }

        AttestationApplication application = AttestationApplication.builder()
                .user(user)
                .mechanicProfile(profile)
                .club(selectedClub)
                .status(AttestationStatus.PENDING)
                .comment("Заявка свободного механика ожидает подтверждения администрацией и выбора аккаунта (Базовый/Премиум)")
                .submittedAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        attestationApplicationRepository.save(application);
        notificationService.notifyFreeMechanicPending(profile);
        log.info("Free mechanic application {} submitted for user {}", application.getApplicationId(), normalizedPhone);

        return toResponse(application);
    }

    @Transactional(readOnly = true)
    public List<FreeMechanicApplicationResponseDTO> listApplications() {
        return attestationApplicationRepository.findAllByOrderBySubmittedAtDesc()
                .stream()
                .filter(this::isFreeMechanicApplication)
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public FreeMechanicApplicationResponseDTO approve(Long applicationId, MechanicApplicationDecisionDTO decision) {
        if (decision == null) {
            throw new IllegalArgumentException("Decision payload is required");
        }
        AttestationApplication application = attestationApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

        if (!isFreeMechanicApplication(application)) {
            throw new IllegalArgumentException("Application does not belong to a free mechanic");
        }

        AccountTypeName targetAccountType = AccountTypeName.from(decision.getTargetAccountType());
        if (!isFreeAccountType(targetAccountType)) {
            throw new IllegalArgumentException("Free mechanic can only be approved with FREE_MECHANIC account types");
        }

        AccountType accountType = accountTypeRepository.findByNameIgnoreCase(targetAccountType.name())
                .orElseThrow(() -> new IllegalStateException("Account type not configured: " + targetAccountType.name()));

        User user = application.getUser();
        MechanicProfile profile = application.getMechanicProfile();

        if (user == null || profile == null) {
            throw new IllegalStateException("Corrupted application: missing user or profile link");
        }

        user.setIsActive(true);
        user.setIsVerified(true);
        user.setAccountType(accountType);
        user.setLastModified(LocalDateTime.now());

        profile.setIsDataVerified(true);
        profile.setVerificationDate(LocalDate.now());
        profile.setUpdatedAt(LocalDate.now());

        ensurePersonalWarehouse(profile);

        application.setStatus(AttestationStatus.APPROVED);
        application.setComment(decision.getComment());
        application.setUpdatedAt(LocalDateTime.now());

        userRepository.save(user);
        mechanicProfileRepository.save(profile);
        attestationApplicationRepository.save(application);
        notificationService.notifyFreeMechanicApproved(profile);

        log.info("Free mechanic application {} approved with account type {}", applicationId, targetAccountType);
        return toResponse(application);
    }

    @Transactional
    public FreeMechanicApplicationResponseDTO reject(Long applicationId, String reason) {
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("Rejection reason is required");
        }

        AttestationApplication application = attestationApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Application not found"));

        if (!isFreeMechanicApplication(application)) {
            throw new IllegalArgumentException("Application does not belong to a free mechanic");
        }

        User user = application.getUser();
        if (user != null) {
            user.setIsActive(false);
            user.setIsVerified(false);
            user.setLastModified(LocalDateTime.now());
            userRepository.save(user);
        }

        application.setStatus(AttestationStatus.REJECTED);
        application.setComment(reason.trim());
        application.setUpdatedAt(LocalDateTime.now());
        attestationApplicationRepository.save(application);

        log.info("Free mechanic application {} rejected", applicationId);
        return toResponse(application);
    }

    private boolean isFreeMechanicApplication(AttestationApplication application) {
        if (application == null || application.getUser() == null || application.getUser().getRole() == null) {
            return false;
        }
        RoleName roleName = RoleName.from(application.getUser().getRole().getName());
        if (roleName != RoleName.MECHANIC) {
            return false;
        }
        AccountType accountType = application.getUser().getAccountType();
        if (accountType == null) {
            return false;
        }
        AccountTypeName accountTypeName = AccountTypeName.from(accountType.getName());
        return isFreeAccountType(accountTypeName);
    }

    private boolean isFreeAccountType(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.FREE_MECHANIC_BASIC
                || accountTypeName == AccountTypeName.FREE_MECHANIC_PREMIUM;
    }

    private void applyCertifications(MechanicProfile profile, List<MechanicCertificationDTO> certifications) {
        if (profile == null || certifications == null) {
            return;
        }
        if (profile.getCertifications() == null) {
            profile.setCertifications(new ArrayList<>());
        }
        profile.getCertifications().clear();
        for (MechanicCertificationDTO dto : certifications) {
            if (dto == null) {
                continue;
            }
            MechanicCertification certification = MechanicCertification.builder()
                    .mechanicProfile(profile)
                    .title(dto.getTitle())
                    .issuer(dto.getIssuer())
                    .issueDate(dto.getIssueDate())
                    .expirationDate(dto.getExpirationDate())
                    .credentialUrl(dto.getCredentialUrl())
                    .description(dto.getDescription())
                    .build();
            profile.getCertifications().add(certification);
        }
    }

    private void applyWorkHistory(MechanicProfile profile, List<MechanicWorkHistoryDTO> workHistory) {
        if (profile == null || workHistory == null) {
            return;
        }
        if (profile.getWorkHistoryEntries() == null) {
            profile.setWorkHistoryEntries(new ArrayList<>());
        }
        profile.getWorkHistoryEntries().clear();
        for (MechanicWorkHistoryDTO dto : workHistory) {
            if (dto == null) {
                continue;
            }
            MechanicWorkHistory entry = MechanicWorkHistory.builder()
                    .mechanicProfile(profile)
                    .organization(dto.getOrganization())
                    .position(dto.getPosition())
                    .startDate(dto.getStartDate())
                    .endDate(dto.getEndDate())
                    .description(dto.getDescription())
                    .build();
            profile.getWorkHistoryEntries().add(entry);
        }
    }

    private void validateRequest(FreeMechanicApplicationRequestDTO request) {
        if (request == null) {
            throw new IllegalArgumentException("Application data is required");
        }
        if (request.getPhone() == null || request.getPhone().trim().isEmpty()) {
            throw new IllegalArgumentException("Phone is required");
        }
        if (request.getPassword() == null || request.getPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }
        if (request.getFullName() == null || request.getFullName().trim().isEmpty()) {
            throw new IllegalArgumentException("Full name is required");
        }
        if (request.getBirthDate() == null) {
            throw new IllegalArgumentException("Birth date is required");
        }
        if (request.getTotalExperienceYears() == null || request.getTotalExperienceYears() < 0) {
            throw new IllegalArgumentException("Total experience must be non-negative");
        }
        if (request.getBowlingExperienceYears() == null || request.getBowlingExperienceYears() < 0) {
            throw new IllegalArgumentException("Bowling experience must be non-negative");
        }
        if (request.getIsEntrepreneur() == null) {
            throw new IllegalArgumentException("Entrepreneur flag is required");
        }
        if (request.getEducationLevelId() == null) {
            throw new IllegalArgumentException("Education level is required");
        }
        if (request.getEducationalInstitution() == null || request.getEducationalInstitution().trim().isEmpty()) {
            throw new IllegalArgumentException("Educational institution is required");
        }
        if (request.getSpecializationId() == null) {
            throw new IllegalArgumentException("Specialization is required");
        }
        if (request.getRegion() == null || request.getRegion().trim().isEmpty()) {
            throw new IllegalArgumentException("Region is required");
        }
        if (request.getSkills() == null || request.getSkills().trim().isEmpty()) {
            throw new IllegalArgumentException("Skills are required");
        }
        if (request.getAdvantages() == null || request.getAdvantages().trim().isEmpty()) {
            throw new IllegalArgumentException("Advantages are required");
        }
    }

    private String normalizePhone(String rawLogin) {
        if (rawLogin == null) {
            return null;
        }

        String trimmed = rawLogin.trim();
        if (trimmed.isEmpty()) {
            return null;
        }

        String digitsOnly = trimmed.replaceAll("\\D", "");

        if (digitsOnly.length() == 11 && digitsOnly.startsWith("8")) {
            return toValidPhone("+7" + digitsOnly.substring(1));
        }

        if (digitsOnly.length() == 11 && digitsOnly.startsWith("7")) {
            return toValidPhone("+7" + digitsOnly.substring(1));
        }

        if (trimmed.startsWith("+")) {
            return toValidPhone("+" + digitsOnly);
        }

        return null;
    }

    private String toValidPhone(String candidate) {
        if (candidate == null) {
            return null;
        }
        if (RUSSIAN_PHONE_PATTERN.matcher(candidate).matches()) {
            return candidate;
        }
        return null;
    }

    private FreeMechanicApplicationResponseDTO toResponse(AttestationApplication application) {
        if (application == null) {
            return null;
        }

        User user = application.getUser();
        MechanicProfile profile = application.getMechanicProfile();
        BowlingClub club = application.getClub();

        return FreeMechanicApplicationResponseDTO.builder()
                .applicationId(application.getApplicationId())
                .userId(user != null ? user.getUserId() : null)
                .mechanicProfileId(profile != null ? profile.getProfileId() : null)
                .phone(user != null ? user.getPhone() : null)
                .fullName(profile != null ? profile.getFullName() : (user != null ? user.getFullName() : null))
                .status(application.getStatus())
                .comment(application.getComment())
                .accountType(user != null && user.getAccountType() != null ? user.getAccountType().getName() : null)
                .clubId(club != null ? club.getClubId() : null)
                .clubName(club != null ? club.getName() : null)
                .isActive(user != null ? user.getIsActive() : null)
                .isVerified(user != null ? user.getIsVerified() : null)
                .isProfileVerified(profile != null ? profile.getIsDataVerified() : null)
                .profileCreatedAt(profile != null ? profile.getCreatedAt() : null)
                .submittedAt(application.getSubmittedAt())
                .updatedAt(application.getUpdatedAt())
                .build();
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
}
