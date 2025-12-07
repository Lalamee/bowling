package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Entity.enums.AttestationStatus;
import ru.bowling.bowlingapp.Enum.AccountTypeName;
import ru.bowling.bowlingapp.Enum.RoleName;
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Security.UserPrincipal;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AuthService implements UserDetailsService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final PasswordEncoder passwordEncoder;
    private final BowlingClubRepository bowlingClubRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final OwnerProfileRepository ownerProfileRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final AdministratorProfileRepository administratorProfileRepository;
    private final ClubWarehouseService clubWarehouseService;
    private final AttestationApplicationRepository attestationApplicationRepository;

    private static final Pattern RUSSIAN_PHONE_PATTERN = Pattern.compile("^\\+7\\d{10}$");

    @Override
    public UserDetails loadUserByUsername(String phone) throws UsernameNotFoundException {
        User user = findUserByLogin(phone);

        return UserPrincipal.create(user);
    }

    @Transactional(readOnly = true)
    public User findUserByPhone(String phone) {
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with phone: " + phone));
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getCurrentUserInfo(String login) {
        User user = findUserByLogin(login);
        return buildUserInfoResponse(user);
    }

    public User authenticateUser(String phone, String password) {
        User user = findUserByLogin(phone);
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid password");
        }
        return user;
    }

    private User findUserByLogin(String login) {
        String normalizedPhone = normalizePhone(login);
        if (normalizedPhone != null) {
            return userRepository.findByPhone(normalizedPhone)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with phone: " + normalizedPhone));
        }
        return userRepository.findByPhone(login)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with phone: " + login));
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

    @Transactional
    public void registerUser(RegisterUserDTO dto,
                             MechanicProfileDTO mechanicDto,
                             OwnerProfileDTO ownerDto,
                             ManagerProfileDTO managerDto,
                             BowlingClubDTO clubDto) {
        AccountType accountType = resolveAccountType(dto);
        AccountTypeName accountTypeName = AccountTypeName.from(accountType.getName());
        validateRegistrationData(dto, mechanicDto, ownerDto, managerDto, clubDto, accountTypeName);

        String normalizedPhone = normalizePhone(dto.getPhone());
        if (normalizedPhone == null) {
            throw new IllegalArgumentException("Invalid phone format");
        }

        if (userRepository.existsByPhone(normalizedPhone)) {
            throw new IllegalArgumentException("Phone already registered");
        }

        Role role = resolveRole(dto, accountTypeName);
        validateRoleAndAccountTypeCombination(role, accountTypeName);

        User user = User.builder()
                .phone(normalizedPhone)
                .passwordHash(passwordEncoder.encode(dto.getPassword()))
                .role(role)
                .registrationDate(LocalDate.now())
                .isActive(resolveInitialActiveFlag(accountTypeName))
                .isVerified(resolveVerificationFlag(accountTypeName))
                .accountType(accountType)
                .build();

        BowlingClub mechanicClub = null;
        BowlingClub managerClub = null;
        MechanicProfile mechanicProfile = null;
        OwnerProfile ownerProfile = null;
        ManagerProfile managerProfile = null;
        AdministratorProfile administratorProfile = null;

        if (isMechanicAccount(accountTypeName)) {
            AccountTypeName mechanicAccountType = accountTypeName;
            mechanicProfile = MechanicProfile.builder()
                    .user(user)
                    .fullName(mechanicDto.getFullName())
                    .birthDate(mechanicDto.getBirthDate())
                    .educationLevelId(mechanicDto.getEducationLevelId())
                    .educationalInstitution(mechanicDto.getEducationalInstitution())
                    .totalExperienceYears(mechanicDto.getTotalExperienceYears())
                    .bowlingExperienceYears(mechanicDto.getBowlingExperienceYears())
                    .isEntrepreneur(Boolean.TRUE.equals(mechanicDto.getIsEntrepreneur()))
                    .specializationId(mechanicDto.getSpecializationId())
                    .skills(mechanicDto.getSkills())
                    .advantages(mechanicDto.getAdvantages())
                    .region(trimOrNull(mechanicDto.getRegion()))
                    .isDataVerified(false)
                    .createdAt(LocalDate.now())
                    .updatedAt(LocalDate.now())
                    .build();
            applyCertifications(mechanicProfile, mechanicDto.getCertifications());
            applyWorkHistory(mechanicProfile, mechanicDto.getWorkHistory());
            if (isClubMechanic(mechanicAccountType)) {
                mechanicClub = bowlingClubRepository.findById(mechanicDto.getClubId())
                        .orElseThrow(() -> new IllegalArgumentException("Selected club not found"));
                mechanicProfile.setClubs(new ArrayList<>(Collections.singletonList(mechanicClub)));
            } else {
                mechanicProfile.setClubs(new ArrayList<>());
            }
            user.setMechanicProfile(mechanicProfile);
        } else if (isOwnerAccountType(accountTypeName)) {
            ownerProfile = OwnerProfile.builder()
                    .user(user)
                    .inn(ownerDto.getInn())
                    .legalName(ownerDto.getLegalName())
                    .contactPerson(ownerDto.getContactPerson())
                    .contactPhone(ownerDto.getContactPhone())
                    .contactEmail(ownerDto.getContactEmail())
                    .isDataVerified(false)
                    .createdAt(LocalDate.now())
                    .updatedAt(LocalDate.now())
                    .build();
            ownerProfile.setClubs(new ArrayList<>());
            user.setOwnerProfile(ownerProfile);
        } else if (isManagerAccount(accountTypeName)) {
            String managerFullName = managerDto != null && managerDto.getFullName() != null
                    ? managerDto.getFullName().trim()
                    : (ownerDto != null ? trimOrNull(ownerDto.getContactPerson()) : null);
            if (managerFullName == null || managerFullName.isEmpty()) {
                managerFullName = normalizedPhone;
            }
            String managerEmail = managerDto != null ? trimOrNull(managerDto.getContactEmail()) : null;
            String managerPhone = managerDto != null && managerDto.getContactPhone() != null
                    ? trimOrNull(managerDto.getContactPhone())
                    : normalizedPhone;
            managerProfile = ManagerProfile.builder()
                    .user(user)
                    .fullName(managerFullName)
                    .contactPhone(managerPhone != null ? managerPhone : normalizedPhone)
                    .contactEmail(managerEmail)
                    .isDataVerified(false)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
            if (managerDto != null && managerDto.getClubId() != null) {
                managerClub = bowlingClubRepository.findById(managerDto.getClubId())
                        .orElseThrow(() -> new IllegalArgumentException("Selected club not found"));
                managerProfile.setClub(managerClub);
            }
            user.setManagerProfile(managerProfile);
        } else if (isAdministratorAccountType(accountTypeName)) {
            administratorProfile = AdministratorProfile.builder()
                    .user(user)
                    .fullName(ownerDto != null ? ownerDto.getContactPerson() : normalizedPhone)
                    .contactPhone(normalizedPhone)
                    .contactEmail(ownerDto != null ? ownerDto.getContactEmail() : null)
                    .isDataVerified(false)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
            user.setAdministratorProfile(administratorProfile);
        }

        userRepository.save(user);

        if (mechanicProfile != null) {
            mechanicProfileRepository.save(mechanicProfile);
            if (isFreeMechanic(accountTypeName)) {
                createFreeMechanicApplication(user, mechanicProfile);
            }
        }

        if (managerProfile != null) {
            managerProfileRepository.save(managerProfile);
        }

        if (administratorProfile != null) {
            administratorProfileRepository.save(administratorProfile);
        }

        if (ownerProfile != null) {
            attachClubToOwner(ownerProfile, ownerDto, clubDto);
            ownerProfileRepository.save(ownerProfile);
        }

        if (mechanicClub != null) {
            BowlingClub finalMechanicClub = mechanicClub;
            ClubStaff clubStaff = clubStaffRepository.findByClubAndUser(mechanicClub, user)
                    .orElseGet(() -> ClubStaff.builder()
                            .club(finalMechanicClub)
                            .user(user)
                            .assignedAt(LocalDateTime.now())
                            .isActive(Boolean.TRUE.equals(user.getIsActive()))
                            .build());
            clubStaff.setRole(user.getRole());
            if (clubStaff.getAssignedAt() == null) {
                clubStaff.setAssignedAt(LocalDateTime.now());
            }
            clubStaffRepository.save(clubStaff);
        }

        if (managerClub != null) {
            BowlingClub finalManagerClub = managerClub;
            ClubStaff clubStaff = clubStaffRepository.findByClubAndUser(managerClub, user)
                    .orElseGet(() -> ClubStaff.builder()
                            .club(finalManagerClub)
                            .user(user)
                            .assignedAt(LocalDateTime.now())
                            .isActive(Boolean.TRUE.equals(user.getIsActive()))
                            .build());
            clubStaff.setRole(user.getRole());
            if (clubStaff.getAssignedAt() == null) {
                clubStaff.setAssignedAt(LocalDateTime.now());
            }
            clubStaffRepository.save(clubStaff);
        }
    }

    @Transactional
    public void changePassword(String phone, String oldPassword, String newPassword) {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid old password");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public void resetPassword(String phone, String newPassword) {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
    
    private void validateRegistrationData(RegisterUserDTO dto,
                                          MechanicProfileDTO mechanicDto,
                                          OwnerProfileDTO ownerDto,
                                          ManagerProfileDTO managerDto,
                                          BowlingClubDTO clubDto,
                                          AccountTypeName accountTypeName) {
        if (dto == null) {
            throw new IllegalArgumentException("User registration data is required");
        }

        if (dto.getPhone() == null || dto.getPhone().trim().isEmpty()) {
            throw new IllegalArgumentException("Phone is required");
        }

        if (dto.getPassword() == null || dto.getPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }

        if (dto.getRoleId() == null || dto.getAccountTypeId() == null) {
            throw new IllegalArgumentException("Role and account type must be specified");
        }

        if (isMechanicAccount(accountTypeName)) {
            if (mechanicDto == null) {
                throw new IllegalArgumentException("Mechanic profile data is required for mechanic account type");
            }
            if (mechanicDto.getFullName() == null || mechanicDto.getFullName().trim().isEmpty()) {
                throw new IllegalArgumentException("Full name is required for mechanic profile");
            }
            if (mechanicDto.getBirthDate() == null) {
                throw new IllegalArgumentException("Birth date is required for mechanic profile");
            }
            if (mechanicDto.getTotalExperienceYears() == null || mechanicDto.getTotalExperienceYears() < 0) {
                throw new IllegalArgumentException("Total experience years must be non-negative");
            }
            if (mechanicDto.getBowlingExperienceYears() == null || mechanicDto.getBowlingExperienceYears() < 0) {
                throw new IllegalArgumentException("Bowling experience years must be non-negative");
            }
            if (isClubMechanic(accountTypeName) && mechanicDto.getClubId() == null) {
                throw new IllegalArgumentException("Club selection is required for employed mechanics");
            }
            if (isFreeMechanic(accountTypeName) && mechanicDto.getClubId() != null) {
                throw new IllegalArgumentException("Free mechanics cannot be attached to a club during registration");
            }
            if (trimOrNull(mechanicDto.getRegion()) == null) {
                throw new IllegalArgumentException("Region is required for mechanic profile");
            }
            if (mechanicDto.getIsEntrepreneur() == null) {
                throw new IllegalArgumentException("Entrepreneur/self-employment flag is required for mechanic profile");
            }
        } else if (isManagerAccount(accountTypeName)) {
            if (managerDto == null) {
                throw new IllegalArgumentException("Manager profile data is required for manager account type");
            }
            if (managerDto.getFullName() == null || managerDto.getFullName().trim().isEmpty()) {
                throw new IllegalArgumentException("Full name is required for manager profile");
            }
            if (managerDto.getClubId() == null) {
                throw new IllegalArgumentException("Club selection is required for manager profile");
            }
        } else if (isOwnerAccountType(accountTypeName)) {
            if (ownerDto == null) {
                throw new IllegalArgumentException("Owner profile data is required for club owner account type");
            }
            if (ownerDto.getInn() == null || ownerDto.getInn().trim().isEmpty()) {
                throw new IllegalArgumentException("INN is required for owner profile");
            }
            if (clubDto == null) {
                throw new IllegalArgumentException("Club data is required for club owner account type");
            }
            if (clubDto.getName() == null || clubDto.getName().trim().isEmpty()) {
                throw new IllegalArgumentException("Club name is required");
            }
            if (clubDto.getAddress() == null || clubDto.getAddress().trim().isEmpty()) {
                throw new IllegalArgumentException("Club address is required");
            }
            if (clubDto.getLanesCount() == null || clubDto.getLanesCount() <= 0) {
                throw new IllegalArgumentException("Club lanes count must be greater than zero");
            }
        }
    }

    private Map<String, Object> buildUserInfoResponse(User user) {
        Map<String, Object> response = new LinkedHashMap<>();

        response.put("id", user.getUserId());
        response.put("phone", user.getPhone());
        response.put("roleId", user.getRole() != null ? user.getRole().getRoleId() : null);
        response.put("role", mapRoleNameForResponse(user.getRole()));
        response.put("accountTypeId", user.getAccountType() != null ? user.getAccountType().getAccountTypeId() : null);
        response.put("accountType", user.getAccountType() != null ? user.getAccountType().getName() : null);
        response.put("isVerified", user.getIsVerified());
        response.put("registrationDate", user.getRegistrationDate() != null ? user.getRegistrationDate().toString() : null);

        response.put("fullName", resolveFullName(user));
        response.put("email", resolveEmail(user));

        if (user.getMechanicProfile() != null) {
            response.put("mechanicProfile", buildMechanicProfile(user.getMechanicProfile()));
        }

        if (user.getOwnerProfile() != null) {
            response.put("ownerProfile", buildOwnerProfile(user.getOwnerProfile()));
        }

        if (user.getManagerProfile() != null) {
            response.put("managerProfile", buildManagerProfile(user.getManagerProfile()));
        }

        if (user.getAdministratorProfile() != null) {
            response.put("administratorProfile", buildAdministratorProfile(user.getAdministratorProfile()));
        }

        return response;
    }

    private String resolveFullName(User user) {
        if (user.getMechanicProfile() != null && isNotBlank(user.getMechanicProfile().getFullName())) {
            return user.getMechanicProfile().getFullName().trim();
        }
        if (user.getOwnerProfile() != null) {
            OwnerProfile ownerProfile = user.getOwnerProfile();
            if (isNotBlank(ownerProfile.getContactPerson())) {
                return ownerProfile.getContactPerson().trim();
            }
            if (isNotBlank(ownerProfile.getLegalName())) {
                return ownerProfile.getLegalName().trim();
            }
        }
        if (user.getManagerProfile() != null && isNotBlank(user.getManagerProfile().getFullName())) {
            return user.getManagerProfile().getFullName().trim();
        }
        if (user.getAdministratorProfile() != null && isNotBlank(user.getAdministratorProfile().getFullName())) {
            return user.getAdministratorProfile().getFullName().trim();
        }
        return user.getPhone();
    }

    private String resolveEmail(User user) {
        if (user.getOwnerProfile() != null && isNotBlank(user.getOwnerProfile().getContactEmail())) {
            return user.getOwnerProfile().getContactEmail().trim();
        }
        if (user.getManagerProfile() != null && isNotBlank(user.getManagerProfile().getContactEmail())) {
            return user.getManagerProfile().getContactEmail().trim();
        }
        if (user.getAdministratorProfile() != null && isNotBlank(user.getAdministratorProfile().getContactEmail())) {
            return user.getAdministratorProfile().getContactEmail().trim();
        }
        return null;
    }

    private Map<String, Object> buildMechanicProfile(MechanicProfile profile) {
        Map<String, Object> result = new LinkedHashMap<>();

        Long profileId = profile.getProfileId();

        if (profileId != null) {
            result.put("profileId", profileId);
            result.put("id", profileId);
        }

        result.put("fullName", trimOrNull(profile.getFullName()));
        result.put("birthDate", profile.getBirthDate() != null ? profile.getBirthDate().toString() : null);
        result.put("isEntrepreneur", profile.getIsEntrepreneur());
        result.put("isVerified", profile.getIsDataVerified());
        result.put("region", trimOrNull(profile.getRegion()));
        result.put("certifications", buildCertificationDtos(profile));
        result.put("workHistory", buildWorkHistoryDtos(profile));

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs()).orElse(Collections.emptyList());
        List<String> clubNames = clubs.stream()
                .map(BowlingClub::getName)
                .filter(this::isNotBlank)
                .map(String::trim)
                .collect(Collectors.toList());

        List<Map<String, Object>> clubDetails = clubs.stream()
                .map(club -> {
                    Map<String, Object> clubInfo = new LinkedHashMap<>();
                    clubInfo.put("id", club.getClubId());
                    clubInfo.put("name", trimOrNull(club.getName()));
                    clubInfo.put("address", trimOrNull(club.getAddress()));
                    return clubInfo;
                })
                .collect(Collectors.toList());

        if (!clubNames.isEmpty()) {
            result.put("clubName", clubNames.get(0));
        }

        clubs.stream()
                .map(BowlingClub::getClubId)
                .filter(Objects::nonNull)
                .findFirst()
                .ifPresent(id -> result.put("clubId", id));

        String address = clubs.stream()
                .map(BowlingClub::getAddress)
                .filter(this::isNotBlank)
                .map(String::trim)
                .findFirst()
                .orElse(null);

        if (address != null) {
            result.put("address", address);
        }

        result.put("clubs", clubNames);
        if (!clubDetails.isEmpty()) {
            result.put("clubsDetailed", clubDetails);
        }
        result.put("status", Boolean.TRUE.equals(profile.getIsEntrepreneur()) ? "Самозанятый" : "Штатный механик");
        result.put("workplaceVerified", Boolean.TRUE.equals(profile.getIsDataVerified()));

        return result;
    }

    private Map<String, Object> buildOwnerProfile(OwnerProfile profile) {
        Map<String, Object> result = new LinkedHashMap<>();

        result.put("legalName", trimOrNull(profile.getLegalName()));
        result.put("contactPerson", trimOrNull(profile.getContactPerson()));
        result.put("contactPhone", trimOrNull(profile.getContactPhone()));
        result.put("contactEmail", trimOrNull(profile.getContactEmail()));
        result.put("inn", trimOrNull(profile.getInn()));
        result.put("isVerified", profile.getIsDataVerified());
        result.put("workplaceVerified", Boolean.TRUE.equals(profile.getIsDataVerified()));

        List<BowlingClub> clubs = resolveOwnerClubs(profile);
        List<String> clubNames = clubs.stream()
                .map(BowlingClub::getName)
                .filter(this::isNotBlank)
                .map(String::trim)
                .collect(Collectors.toList());

        List<Map<String, Object>> clubDetails = clubs.stream()
                .map(club -> {
                    Map<String, Object> info = new LinkedHashMap<>();
                    info.put("id", club.getClubId());
                    info.put("name", trimOrNull(club.getName()));
                    info.put("address", trimOrNull(club.getAddress()));
                    return info;
                })
                .filter(info -> info.get("id") != null || info.get("name") != null)
                .collect(Collectors.toList());

        if (!clubNames.isEmpty()) {
            result.put("clubName", clubNames.get(0));
        }

        clubs.stream()
                .map(BowlingClub::getClubId)
                .filter(Objects::nonNull)
                .findFirst()
                .ifPresent(id -> result.put("clubId", id));

        String address = clubs.stream()
                .map(BowlingClub::getAddress)
                .filter(this::isNotBlank)
                .map(String::trim)
                .findFirst()
                .orElse(null);

        if (address != null) {
            result.put("address", address);
        }

        if (!clubDetails.isEmpty()) {
            result.put("clubsDetailed", clubDetails);
            Map<String, Object> primaryClub = clubDetails.get(0);
            result.putIfAbsent("clubId", primaryClub.get("id"));
            Object primaryName = primaryClub.get("name");
            if (primaryName instanceof String primaryNameStr && isNotBlank(primaryNameStr)) {
                result.putIfAbsent("clubName", primaryNameStr);
            }
            Object primaryAddress = primaryClub.get("address");
            if (primaryAddress instanceof String primaryAddressStr && isNotBlank(primaryAddressStr)) {
                result.putIfAbsent("address", primaryAddressStr);
            }
        }

        result.put("status", "Собственник");
        result.put("clubs", clubNames);

        Integer totalLanes = clubs.stream()
                .map(BowlingClub::getLanesCount)
                .filter(Objects::nonNull)
                .reduce(Integer::sum)
                .orElse(null);

        if (totalLanes != null && totalLanes > 0) {
            result.put("lanes", totalLanes.toString());
        }

        List<String> equipment = clubs.stream()
                .flatMap(club -> Optional.ofNullable(club.getEquipmentTypes()).orElseGet(ArrayList::new).stream())
                .map(type -> {
                    if (type.getEquipmentType() != null && isNotBlank(type.getEquipmentType().getName())) {
                        return type.getEquipmentType().getName().trim();
                    }
                    return trimOrNull(type.getOtherName());
                })
                .filter(this::isNotBlank)
                .map(String::trim)
                .distinct()
                .collect(Collectors.toList());

        if (!equipment.isEmpty()) {
            result.put("equipment", String.join(", ", equipment));
        }

        return result;
    }

    private Map<String, Object> buildManagerProfile(ManagerProfile profile) {
        Map<String, Object> result = new LinkedHashMap<>();

        result.put("fullName", trimOrNull(profile.getFullName()));
        result.put("contactPhone", trimOrNull(profile.getContactPhone()));
        result.put("contactEmail", trimOrNull(profile.getContactEmail()));
        result.put("status", "Менеджер");
        result.put("isVerified", profile.getIsDataVerified());
        result.put("workplaceVerified", Boolean.TRUE.equals(profile.getIsDataVerified()));

        BowlingClub club = profile.getClub();
        List<String> clubs = new ArrayList<>();
        List<Map<String, Object>> clubsDetailed = new ArrayList<>();
        if (club != null) {
            String clubName = trimOrNull(club.getName());
            if (clubName != null) {
                clubs.add(clubName);
                result.put("clubName", clubName);
            }
            String address = trimOrNull(club.getAddress());
            if (address != null) {
                result.put("address", address);
            }

            Long clubId = club.getClubId();
            if (clubId != null) {
                result.put("clubId", clubId);
            }

            Map<String, Object> clubInfo = new LinkedHashMap<>();
            clubInfo.put("id", clubId);
            clubInfo.put("clubId", clubId);
            clubInfo.put("name", clubName);
            clubInfo.put("address", address);
            clubInfo.put("contactPhone", trimOrNull(club.getContactPhone()));
            clubInfo.put("contactEmail", trimOrNull(club.getContactEmail()));
            clubInfo.put("lanes", club.getLanesCount());

            result.put("club", clubInfo);
            clubsDetailed.add(clubInfo);
        }
        result.put("clubs", clubs);
        if (!clubsDetailed.isEmpty()) {
            result.put("clubsDetailed", clubsDetailed);
        }

        return result;
    }

    private Map<String, Object> buildAdministratorProfile(AdministratorProfile profile) {
        Map<String, Object> result = new LinkedHashMap<>();

        result.put("fullName", trimOrNull(profile.getFullName()));
        result.put("contactPhone", trimOrNull(profile.getContactPhone()));
        result.put("contactEmail", trimOrNull(profile.getContactEmail()));
        result.put("status", "Администратор");
        result.put("isVerified", profile.getIsDataVerified());

        BowlingClub club = profile.getClub();
        List<String> clubs = new ArrayList<>();
        List<Map<String, Object>> clubsDetailed = new ArrayList<>();
        if (club != null) {
            String clubName = trimOrNull(club.getName());
            if (clubName != null) {
                clubs.add(clubName);
                result.put("clubName", clubName);
            }
            String address = trimOrNull(club.getAddress());
            if (address != null) {
                result.put("address", address);
            }

            Long clubId = club.getClubId();
            if (clubId != null) {
                result.put("clubId", clubId);
            }

            Map<String, Object> clubInfo = new LinkedHashMap<>();
            clubInfo.put("id", clubId);
            clubInfo.put("clubId", clubId);
            clubInfo.put("name", clubName);
            clubInfo.put("address", address);
            clubInfo.put("contactPhone", trimOrNull(club.getContactPhone()));
            clubInfo.put("contactEmail", trimOrNull(club.getContactEmail()));
            clubInfo.put("lanes", club.getLanesCount());

            result.put("club", clubInfo);
            clubsDetailed.add(clubInfo);
        }
        result.put("clubs", clubs);
        if (!clubsDetailed.isEmpty()) {
            result.put("clubsDetailed", clubsDetailed);
        }

        return result;
    }

    private AccountType resolveAccountType(RegisterUserDTO dto) {
        if (dto.getAccountTypeId() == null) {
            throw new IllegalArgumentException("Account type is required");
        }
        return accountTypeRepository.findById(dto.getAccountTypeId().longValue())
                .orElseThrow(() -> new IllegalArgumentException("Account type not found"));
    }

    private Role resolveRole(RegisterUserDTO dto, AccountTypeName accountTypeName) {
        RoleName expectedRoleName = mapRoleByAccountType(accountTypeName);
        if (dto.getRoleId() != null) {
            Role provided = roleRepository.findById(dto.getRoleId().longValue())
                    .orElseThrow(() -> new IllegalArgumentException("Role not found"));
            RoleName providedName = RoleName.from(provided.getName());
            if (!providedName.equals(expectedRoleName)) {
                throw new IllegalArgumentException("Provided role does not match selected account type");
            }
            return provided;
        }
        return roleByName(expectedRoleName.name());
    }

    private Role roleByName(String name) {
        return roleRepository.findByNameIgnoreCase(name)
                .orElseThrow(() -> new IllegalArgumentException("Role not found: " + name));
    }

    private RoleName mapRoleByAccountType(AccountTypeName type) {
        return switch (type) {
            case MAIN_ADMIN -> RoleName.ADMIN;
            case CLUB_OWNER -> RoleName.CLUB_OWNER;
            case CLUB_MANAGER -> RoleName.HEAD_MECHANIC;
            case INDIVIDUAL, FREE_MECHANIC_BASIC, FREE_MECHANIC_PREMIUM -> RoleName.MECHANIC;
        };
    }

    private boolean isMechanicAccount(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.INDIVIDUAL
                || accountTypeName == AccountTypeName.FREE_MECHANIC_BASIC
                || accountTypeName == AccountTypeName.FREE_MECHANIC_PREMIUM;
    }

    private boolean isFreeMechanic(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.FREE_MECHANIC_BASIC
                || accountTypeName == AccountTypeName.FREE_MECHANIC_PREMIUM;
    }

    private boolean isClubMechanic(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.INDIVIDUAL;
    }

    private boolean isManagerAccount(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.CLUB_MANAGER;
    }

    private boolean isOwnerAccountType(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.CLUB_OWNER;
    }

    private boolean isAdministratorAccountType(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.MAIN_ADMIN;
    }

    private boolean resolveVerificationFlag(AccountTypeName accountTypeName) {
        return accountTypeName == AccountTypeName.MAIN_ADMIN;
    }

    private boolean resolveInitialActiveFlag(AccountTypeName accountTypeName) {
        return switch (accountTypeName) {
            case FREE_MECHANIC_BASIC, FREE_MECHANIC_PREMIUM -> false;
            case CLUB_OWNER, CLUB_MANAGER -> false;
            case MAIN_ADMIN -> true;
            case INDIVIDUAL -> true;
        };
    }

    private void validateRoleAndAccountTypeCombination(Role role, AccountTypeName accountTypeName) {
        if (role == null || role.getName() == null) {
            throw new IllegalArgumentException("Role is required");
        }
        RoleName providedRole = RoleName.from(role.getName());
        RoleName expectedRole = mapRoleByAccountType(accountTypeName);
        if (!providedRole.equals(expectedRole)) {
            throw new IllegalArgumentException("Role " + providedRole + " is not allowed for account type " + accountTypeName);
        }
    }

    private void createFreeMechanicApplication(User user, MechanicProfile mechanicProfile) {
        if (user == null || mechanicProfile == null) {
            return;
        }

        AttestationApplication application = AttestationApplication.builder()
                .user(user)
                .mechanicProfile(mechanicProfile)
                .status(AttestationStatus.PENDING)
                .comment("Регистрация свободного механика ожидает подтверждения администрацией и выбора аккаунта (Базовый/Премиум)")
                .submittedAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        attestationApplicationRepository.save(application);
    }

    private void attachClubToOwner(OwnerProfile ownerProfile, OwnerProfileDTO ownerDto, BowlingClubDTO clubDto) {
        if (ownerProfile == null || clubDto == null) {
            return;
        }

        String clubName = trimOrNull(clubDto.getName());
        if (clubName == null && ownerDto != null) {
            clubName = trimOrNull(ownerDto.getLegalName());
        }

        String clubAddress = trimOrNull(clubDto.getAddress());
        if (clubName == null || clubAddress == null) {
            return;
        }

        String contactPhone = trimOrNull(clubDto.getContactPhone());
        if (contactPhone == null && ownerDto != null) {
            contactPhone = trimOrNull(ownerDto.getContactPhone());
        }

        String contactEmail = trimOrNull(clubDto.getContactEmail());
        if (contactEmail == null && ownerDto != null) {
            contactEmail = trimOrNull(ownerDto.getContactEmail());
        }

        Integer lanesCount = clubDto.getLanesCount();

        String finalClubName = clubName;
        BowlingClub club = bowlingClubRepository
                .findByNameIgnoreCaseAndAddressIgnoreCase(clubName, clubAddress)
                .orElseGet(() -> BowlingClub.builder()
                        .name(finalClubName)
                        .address(clubAddress)
                        .build());

        boolean isNewClub = club.getClubId() == null;

        club.setOwner(ownerProfile);
        club.setContactPhone(contactPhone);
        club.setContactEmail(contactEmail);
        club.setLanesCount(lanesCount);
        if (isNewClub) {
            club.setCreatedAt(LocalDate.now());
            club.setIsActive(Boolean.TRUE);
            club.setIsVerified(Boolean.FALSE);
        }
        club.setUpdatedAt(LocalDate.now());

        BowlingClub savedClub = bowlingClubRepository.save(club);

        if (isNewClub) {
            clubWarehouseService.initializeWarehouseForClub(savedClub);
        }

        if (ownerProfile.getClubs() == null) {
            ownerProfile.setClubs(new ArrayList<>());
        }

        boolean alreadyLinked = ownerProfile.getClubs().stream()
                .anyMatch(existing -> Objects.equals(existing.getClubId(), savedClub.getClubId()));

        if (!alreadyLinked) {
            ownerProfile.getClubs().add(savedClub);
        }
    }

    private String mapRoleNameForResponse(Role role) {
        if (role == null || role.getName() == null) {
            return null;
        }
        return mapRoleNameForResponse(role.getName());
    }

    private String mapRoleNameForResponse(String roleName) {
        if (roleName == null) {
            return null;
        }
        String normalized = normalizeRoleName(roleName);
        if (normalized == null) {
            return roleName;
        }
        if (normalized.contains("HEADMECHANIC")
                || normalized.contains("CHIEFMECHANIC")
                || normalized.contains("GLAVNYIMECHANIK")) {
            return "MANAGER";
        }
        return roleName;
    }

    private String normalizeRoleName(String value) {
        if (value == null) {
            return null;
        }
        return value.replaceAll("[\\s_\\-]", "").toUpperCase(Locale.ROOT);
    }

    private List<BowlingClub> resolveOwnerClubs(OwnerProfile profile) {
        if (profile == null) {
            return Collections.emptyList();
        }

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs()).orElse(Collections.emptyList());
        if (!clubs.isEmpty()) {
            return clubs;
        }

        Long ownerId = profile.getOwnerId();
        if (ownerId == null) {
            return Collections.emptyList();
        }

        return bowlingClubRepository.findAllByOwnerOwnerId(ownerId);
    }

    private boolean isNotBlank(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private String trimOrNull(String value) {
        return isNotBlank(value) ? value.trim() : null;
    }

    private List<MechanicCertificationDTO> buildCertificationDtos(MechanicProfile profile) {
        return Optional.ofNullable(profile)
                .map(MechanicProfile::getCertifications)
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(cert -> MechanicCertificationDTO.builder()
                        .certificationId(cert.getCertificationId())
                        .title(cert.getTitle())
                        .issuer(cert.getIssuer())
                        .issueDate(cert.getIssueDate())
                        .expirationDate(cert.getExpirationDate())
                        .credentialUrl(cert.getCredentialUrl())
                        .description(cert.getDescription())
                        .build())
                .collect(Collectors.toList());
    }

    private List<MechanicWorkHistoryDTO> buildWorkHistoryDtos(MechanicProfile profile) {
        return Optional.ofNullable(profile)
                .map(MechanicProfile::getWorkHistoryEntries)
                .orElse(List.of())
                .stream()
                .filter(Objects::nonNull)
                .map(entry -> MechanicWorkHistoryDTO.builder()
                        .historyId(entry.getHistoryId())
                        .organization(entry.getOrganization())
                        .position(entry.getPosition())
                        .startDate(entry.getStartDate())
                        .endDate(entry.getEndDate())
                        .description(entry.getDescription())
                        .build())
                .collect(Collectors.toList());
    }

    private void applyCertifications(MechanicProfile profile, List<MechanicCertificationDTO> certifications) {
        if (profile == null) {
            return;
        }
        profile.getCertifications().clear();
        if (certifications == null) {
            return;
        }
        for (MechanicCertificationDTO dto : certifications) {
            if (dto == null) {
                continue;
            }
            MechanicCertification certification = MechanicCertification.builder()
                    .mechanicProfile(profile)
                    .title(trimOrNull(dto.getTitle()))
                    .issuer(trimOrNull(dto.getIssuer()))
                    .issueDate(dto.getIssueDate())
                    .expirationDate(dto.getExpirationDate())
                    .credentialUrl(trimOrNull(dto.getCredentialUrl()))
                    .description(trimOrNull(dto.getDescription()))
                    .build();
            profile.getCertifications().add(certification);
        }
    }

    private void applyWorkHistory(MechanicProfile profile, List<MechanicWorkHistoryDTO> history) {
        if (profile == null) {
            return;
        }
        profile.getWorkHistoryEntries().clear();
        if (history == null) {
            return;
        }
        for (MechanicWorkHistoryDTO dto : history) {
            if (dto == null) {
                continue;
            }
            MechanicWorkHistory entry = MechanicWorkHistory.builder()
                    .mechanicProfile(profile)
                    .organization(trimOrNull(dto.getOrganization()))
                    .position(trimOrNull(dto.getPosition()))
                    .startDate(dto.getStartDate())
                    .endDate(dto.getEndDate())
                    .description(trimOrNull(dto.getDescription()))
                    .build();
            profile.getWorkHistoryEntries().add(entry);
        }
    }
}
