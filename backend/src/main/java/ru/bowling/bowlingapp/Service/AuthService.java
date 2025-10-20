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
import ru.bowling.bowlingapp.Repository.*;
import ru.bowling.bowlingapp.Security.UserPrincipal;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthService implements UserDetailsService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final PasswordEncoder passwordEncoder;

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

    private boolean isMechanicAccountType(String accountTypeName) {
        String normalized = normalizeAccountTypeName(accountTypeName);
        return "INDIVIDUAL".equals(normalized)
                || "МЕХАНИК".equals(normalized)
                || "ГЛАВНЫЙ МЕХАНИК".equals(normalized);
    }

    private boolean isOwnerAccountType(String accountTypeName) {
        String normalized = normalizeAccountTypeName(accountTypeName);
        return "CLUB_OWNER".equals(normalized)
                || "ВЛАДЕЛЕЦ".equals(normalized);
    }

    private String normalizeAccountTypeName(String accountTypeName) {
        if (accountTypeName == null) {
            return null;
        }
        return accountTypeName.trim().toUpperCase(Locale.ROOT);
    }

    @Transactional
    public void registerUser(RegisterUserDTO dto, MechanicProfileDTO mechanicDto, OwnerProfileDTO ownerDto) {
        validateRegistrationData(dto, mechanicDto, ownerDto);
        
        if (userRepository.existsByPhone(dto.getPhone())) {
            throw new IllegalArgumentException("Phone already registered");
        }

        Role role = roleRepository.findById(dto.getRoleId())
                .orElseThrow(() -> new IllegalArgumentException("Role not found"));
        
        AccountType accountType = accountTypeRepository.findById(dto.getAccountTypeId())
                .orElseThrow(() -> new IllegalArgumentException("Account type not found"));

        User user = User.builder()
                .phone(dto.getPhone())
                .passwordHash(passwordEncoder.encode(dto.getPassword()))
                .role(role)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(false)
                .accountType(accountType)
                .build();

        // Используем имена вместо ID для надежности
        String accountTypeName = accountType.getName();

        if (isMechanicAccountType(accountTypeName)) { // механик/гл. механик
            MechanicProfile profile = MechanicProfile.builder()
                    .user(user)
                    .fullName(mechanicDto.getFullName())
                    .birthDate(mechanicDto.getBirthDate())
                    .educationLevelId(mechanicDto.getEducationLevelId())
                    .educationalInstitution(mechanicDto.getEducationalInstitution())
                    .totalExperienceYears(mechanicDto.getTotalExperienceYears())
                    .bowlingExperienceYears(mechanicDto.getBowlingExperienceYears())
                    .isEntrepreneur(mechanicDto.isEntrepreneur())
                    .specializationId(mechanicDto.getSpecializationId())
                    .skills(mechanicDto.getSkills())
                    .advantages(mechanicDto.getAdvantages())
                    .workPlaces(mechanicDto.getWorkPlaces())
                    .workPeriods(mechanicDto.getWorkPeriods())
                    .isDataVerified(false)
                    .createdAt(LocalDate.now())
                    .updatedAt(LocalDate.now())
                    .build();
            user.setMechanicProfile(profile);
        } else if (isOwnerAccountType(accountTypeName)) { // владелец
            OwnerProfile profile = OwnerProfile.builder()
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
            user.setOwnerProfile(profile);
        }

        userRepository.save(user); // Явное сохранение для надежности
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
    
    private void validateRegistrationData(RegisterUserDTO dto, MechanicProfileDTO mechanicDto, OwnerProfileDTO ownerDto) {
        if (dto == null) {
            throw new IllegalArgumentException("User registration data is required");
        }
        
        if (dto.getPhone() == null || dto.getPhone().trim().isEmpty()) {
            throw new IllegalArgumentException("Phone is required");
        }
        
        if (dto.getPassword() == null || dto.getPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }
        
        if (dto.getRoleId() == null) {
            throw new IllegalArgumentException("Role ID is required");
        }
        
        if (dto.getAccountTypeId() == null) {
            throw new IllegalArgumentException("Account type ID is required");
        }
        
        
        AccountType accountType = accountTypeRepository.findById(dto.getAccountTypeId()).orElse(null);
        if (accountType != null) {
            if (isMechanicAccountType(accountType.getName())) {
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
            } else if (isOwnerAccountType(accountType.getName())) {
                if (ownerDto == null) {
                    throw new IllegalArgumentException("Owner profile data is required for club owner account type");
                }
                if (ownerDto.getInn() == null || ownerDto.getInn().trim().isEmpty()) {
                    throw new IllegalArgumentException("INN is required for owner profile");
                }
            }
        }
    }

    private Map<String, Object> buildUserInfoResponse(User user) {
        Map<String, Object> response = new LinkedHashMap<>();

        response.put("id", user.getUserId());
        response.put("phone", user.getPhone());
        response.put("roleId", user.getRole() != null ? user.getRole().getRoleId() : null);
        response.put("role", user.getRole() != null ? user.getRole().getName() : null);
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
        return user.getPhone();
    }

    private String resolveEmail(User user) {
        if (user.getOwnerProfile() != null && isNotBlank(user.getOwnerProfile().getContactEmail())) {
            return user.getOwnerProfile().getContactEmail().trim();
        }
        return null;
    }

    private Map<String, Object> buildMechanicProfile(MechanicProfile profile) {
        Map<String, Object> result = new LinkedHashMap<>();

        result.put("fullName", trimOrNull(profile.getFullName()));
        result.put("birthDate", profile.getBirthDate() != null ? profile.getBirthDate().toString() : null);
        result.put("isEntrepreneur", profile.getIsEntrepreneur());
        result.put("isVerified", profile.getIsDataVerified());
        result.put("workPlaces", trimOrNull(profile.getWorkPlaces()));
        result.put("workPeriods", trimOrNull(profile.getWorkPeriods()));

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs()).orElse(Collections.emptyList());
        List<String> clubNames = clubs.stream()
                .map(BowlingClub::getName)
                .filter(this::isNotBlank)
                .map(String::trim)
                .collect(Collectors.toList());

        if (!clubNames.isEmpty()) {
            result.put("clubName", clubNames.get(0));
        }

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

        List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs()).orElse(Collections.emptyList());
        List<String> clubNames = clubs.stream()
                .map(BowlingClub::getName)
                .filter(this::isNotBlank)
                .map(String::trim)
                .collect(Collectors.toList());

        if (!clubNames.isEmpty()) {
            result.put("clubName", clubNames.get(0));
        }

        String address = clubs.stream()
                .map(BowlingClub::getAddress)
                .filter(this::isNotBlank)
                .map(String::trim)
                .findFirst()
                .orElse(null);

        if (address != null) {
            result.put("address", address);
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

    private boolean isNotBlank(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private String trimOrNull(String value) {
        return isNotBlank(value) ? value.trim() : null;
    }
}
