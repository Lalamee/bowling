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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

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

    private Map<String, Object> buildUserInfoResponse(User user) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("id", user.getUserId());
        response.put("phone", user.getPhone());
        response.put("roleId", Optional.ofNullable(user.getRole()).map(Role::getRoleId).orElse(null));
        response.put("accountTypeId", Optional.ofNullable(user.getAccountType()).map(AccountType::getAccountTypeId).orElse(null));
        response.put("isVerified", user.getIsVerified());
        response.put("registrationDate", user.getRegistrationDate());
        response.put("isActive", user.getIsActive());

        applyMechanicProfile(response, user);
        applyOwnerProfile(response, user);

        return response;
    }

    private void applyMechanicProfile(Map<String, Object> response, User user) {
        MechanicProfile mechanicProfile = user.getMechanicProfile();
        if (mechanicProfile == null) {
            return;
        }

        Map<String, Object> mechanicMap = new LinkedHashMap<>();
        mechanicMap.put("profileId", mechanicProfile.getProfileId());
        mechanicMap.put("fullName", mechanicProfile.getFullName());
        mechanicMap.put("birthDate", mechanicProfile.getBirthDate());
        mechanicMap.put("educationLevelId", mechanicProfile.getEducationLevelId());
        mechanicMap.put("educationalInstitution", mechanicProfile.getEducationalInstitution());
        mechanicMap.put("totalExperienceYears", mechanicProfile.getTotalExperienceYears());
        mechanicMap.put("bowlingExperienceYears", mechanicProfile.getBowlingExperienceYears());
        mechanicMap.put("isEntrepreneur", mechanicProfile.getIsEntrepreneur());
        mechanicMap.put("specializationId", mechanicProfile.getSpecializationId());
        mechanicMap.put("skills", mechanicProfile.getSkills());
        mechanicMap.put("advantages", mechanicProfile.getAdvantages());
        mechanicMap.put("workPlaces", mechanicProfile.getWorkPlaces());
        mechanicMap.put("workPeriods", mechanicProfile.getWorkPeriods());
        mechanicMap.put("isVerified", mechanicProfile.getIsDataVerified());
        mechanicMap.put("rating", mechanicProfile.getRating());
        mechanicMap.put("verificationDate", mechanicProfile.getVerificationDate());
        mechanicMap.put("createdAt", mechanicProfile.getCreatedAt());
        mechanicMap.put("updatedAt", mechanicProfile.getUpdatedAt());

        List<String> clubNames = new ArrayList<>();
        List<Map<String, Object>> clubs = new ArrayList<>();
        if (mechanicProfile.getClubs() != null) {
            for (BowlingClub club : mechanicProfile.getClubs()) {
                if (club == null) {
                    continue;
                }
                Map<String, Object> clubInfo = new LinkedHashMap<>();
                clubInfo.put("clubId", club.getClubId());
                clubInfo.put("name", club.getName());
                clubInfo.put("address", club.getAddress());
                clubInfo.put("isVerified", club.getIsVerified());
                clubInfo.put("lanesCount", club.getLanesCount());
                clubs.add(clubInfo);
                if (club.getName() != null && !club.getName().isBlank()) {
                    clubNames.add(club.getName());
                }
            }
        }

        mechanicMap.put("clubs", clubNames);
        if (!clubs.isEmpty()) {
            mechanicMap.put("clubDetails", clubs);
            Map<String, Object> primaryClub = clubs.get(0);
            Object clubName = primaryClub.get("name");
            if (clubName instanceof String && !((String) clubName).isBlank()) {
                mechanicMap.put("clubName", clubName);
                response.put("clubName", clubName);
            }
            Object address = primaryClub.get("address");
            if (address instanceof String && !((String) address).isBlank()) {
                mechanicMap.put("address", address);
                response.put("address", address);
            }
        }

        String fullName = mechanicProfile.getFullName();
        if (fullName != null && !fullName.isBlank()) {
            response.put("fullName", fullName);
        }

        Boolean entrepreneur = mechanicProfile.getIsEntrepreneur();
        if (entrepreneur != null) {
            String status = entrepreneur ? "Самозанятый" : "Штатный механик";
            mechanicMap.put("status", status);
            response.put("status", status);
        }

        response.put("mechanicProfile", mechanicMap);
    }

    private void applyOwnerProfile(Map<String, Object> response, User user) {
        OwnerProfile ownerProfile = user.getOwnerProfile();
        if (ownerProfile == null) {
            return;
        }

        Map<String, Object> ownerMap = new LinkedHashMap<>();
        ownerMap.put("ownerId", ownerProfile.getOwnerId());
        ownerMap.put("inn", ownerProfile.getInn());
        ownerMap.put("legalName", ownerProfile.getLegalName());
        ownerMap.put("contactPerson", ownerProfile.getContactPerson());
        ownerMap.put("contactPhone", ownerProfile.getContactPhone());
        ownerMap.put("contactEmail", ownerProfile.getContactEmail());
        ownerMap.put("isVerified", ownerProfile.getIsDataVerified());
        ownerMap.put("verificationDate", ownerProfile.getVerificationDate());
        ownerMap.put("createdAt", ownerProfile.getCreatedAt());
        ownerMap.put("updatedAt", ownerProfile.getUpdatedAt());

        List<String> clubNames = new ArrayList<>();
        if (ownerProfile.getClubs() != null && !ownerProfile.getClubs().isEmpty()) {
            for (BowlingClub club : ownerProfile.getClubs()) {
                if (club == null) {
                    continue;
                }
                if (club.getName() != null && !club.getName().isBlank()) {
                    clubNames.add(club.getName());
                }
            }
            ownerMap.put("clubs", clubNames);

            BowlingClub primaryClub = ownerProfile.getClubs().get(0);
            if (primaryClub != null) {
                if (primaryClub.getName() != null && !primaryClub.getName().isBlank()) {
                    ownerMap.put("clubName", primaryClub.getName());
                    if (!response.containsKey("clubName") || response.get("clubName") == null ||
                            response.get("clubName").toString().isBlank()) {
                        response.put("clubName", primaryClub.getName());
                    }
                }
                if (primaryClub.getAddress() != null && !primaryClub.getAddress().isBlank()) {
                    ownerMap.put("address", primaryClub.getAddress());
                    if (!response.containsKey("address") || response.get("address") == null ||
                            response.get("address").toString().isBlank()) {
                        response.put("address", primaryClub.getAddress());
                    }
                }
                if (primaryClub.getLanesCount() != null) {
                    ownerMap.put("lanes", primaryClub.getLanesCount());
                }
            }
        } else {
            ownerMap.put("clubs", clubNames);
        }

        String ownerStatus = "Владелец клуба";
        ownerMap.put("status", ownerStatus);
        if (!response.containsKey("status") || response.get("status") == null ||
                response.get("status").toString().isBlank()) {
            response.put("status", ownerStatus);
        }

        String contactPerson = ownerProfile.getContactPerson();
        if (contactPerson != null && !contactPerson.isBlank()) {
            if (!response.containsKey("fullName") || response.get("fullName") == null ||
                    response.get("fullName").toString().isBlank()) {
                response.put("fullName", contactPerson);
            }
        } else if (ownerProfile.getLegalName() != null && !ownerProfile.getLegalName().isBlank()) {
            if (!response.containsKey("fullName") || response.get("fullName") == null ||
                    response.get("fullName").toString().isBlank()) {
                response.put("fullName", ownerProfile.getLegalName());
            }
        }

        response.put("ownerProfile", ownerMap);
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

        if ("INDIVIDUAL".equals(accountTypeName)) { // механик/гл. механик
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
        } else if ("CLUB_OWNER".equals(accountTypeName)) { // владелец
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
            if ("INDIVIDUAL".equals(accountType.getName())) {
                if (mechanicDto == null) {
                    throw new IllegalArgumentException("Mechanic profile data is required for INDIVIDUAL account type");
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
            } else if ("CLUB_OWNER".equals(accountType.getName())) {
                if (ownerDto == null) {
                    throw new IllegalArgumentException("Owner profile data is required for CLUB_OWNER account type");
                }
                if (ownerDto.getInn() == null || ownerDto.getInn().trim().isEmpty()) {
                    throw new IllegalArgumentException("INN is required for owner profile");
                }
            }
        }
    }
}
