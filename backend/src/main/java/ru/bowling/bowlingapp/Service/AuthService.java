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

@Service
@RequiredArgsConstructor
public class AuthService implements UserDetailsService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        User user = userRepository.findByPhone(identifier)
                .or(() -> userRepository.findByEmailIgnoreCase(identifier))
                .orElseThrow(() -> new UsernameNotFoundException("User not found with identifier: " + identifier));

        return UserPrincipal.create(user);
    }

    public User findUserByPhone(String phone) {
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with phone: " + phone));
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
