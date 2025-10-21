package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.ClubStaffMemberDTO;
import ru.bowling.bowlingapp.DTO.CreateManagerRequestDTO;
import ru.bowling.bowlingapp.DTO.CreateManagerResponseDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ClubStaffService {

    private final BowlingClubRepository bowlingClubRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<ClubStaffMemberDTO> getClubStaff(Long clubId) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        List<ClubStaffMemberDTO> staff = new ArrayList<>();

        OwnerProfile owner = club.getOwner();
        if (owner != null && owner.getUser() != null) {
            User ownerUser = owner.getUser();
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(ownerUser.getUserId())
                    .fullName(resolveOwnerName(owner))
                    .phone(ownerUser.getPhone())
                    .email(owner.getContactEmail())
                    .role("OWNER")
                    .isActive(ownerUser.getIsActive())
                    .build());
        }

        List<ManagerProfile> managers = managerProfileRepository.findByClub_ClubId(clubId);
        for (ManagerProfile manager : managers) {
            User managerUser = manager.getUser();
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(managerUser != null ? managerUser.getUserId() : null)
                    .fullName(trim(manager.getFullName(), managerUser != null ? managerUser.getPhone() : null))
                    .phone(manager.getContactPhone() != null ? manager.getContactPhone() : (managerUser != null ? managerUser.getPhone() : null))
                    .email(manager.getContactEmail())
                    .role("MANAGER")
                    .isActive(managerUser != null ? managerUser.getIsActive() : Boolean.TRUE)
                    .build());
        }

        List<MechanicProfile> mechanics = mechanicProfileRepository.findByClubs_ClubId(clubId);
        for (MechanicProfile mechanic : mechanics) {
            User mechanicUser = mechanic.getUser();
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(mechanicUser != null ? mechanicUser.getUserId() : null)
                    .fullName(trim(mechanic.getFullName(), mechanicUser != null ? mechanicUser.getPhone() : null))
                    .phone(mechanicUser != null ? mechanicUser.getPhone() : null)
                    .role("MECHANIC")
                    .isActive(mechanicUser != null ? mechanicUser.getIsActive() : Boolean.TRUE)
                    .build());
        }

        return staff;
    }

    @Transactional
    public CreateManagerResponseDTO createManager(Long clubId, CreateManagerRequestDTO request) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        String normalizedPhone = normalizePhone(request.getPhone());
        if (normalizedPhone == null) {
            throw new IllegalArgumentException("Invalid phone format");
        }

        if (userRepository.existsByPhone(normalizedPhone)) {
            throw new IllegalArgumentException("Phone already registered");
        }

        AccountType accountType = resolveManagerAccountType();
        Role role = resolveManagerRole();

        String rawPassword = Optional.ofNullable(request.getPassword()).filter(p -> !p.isBlank())
                .orElseGet(this::generatePassword);

        User user = User.builder()
                .phone(normalizedPhone)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .role(role)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(false)
                .accountType(accountType)
                .build();

        ManagerProfile profile = ManagerProfile.builder()
                .user(user)
                .club(club)
                .fullName(trim(request.getFullName(), normalizedPhone))
                .contactPhone(normalizedPhone)
                .contactEmail(trimNullable(request.getEmail()))
                .isDataVerified(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        user.setManagerProfile(profile);
        userRepository.save(user);

        return CreateManagerResponseDTO.builder()
                .userId(user.getUserId())
                .fullName(profile.getFullName())
                .phone(user.getPhone())
                .password(rawPassword)
                .role(role.getName())
                .build();
    }

    private AccountType resolveManagerAccountType() {
        return accountTypeRepository.findByNameIgnoreCase("Менеджер")
                .or(() -> accountTypeRepository.findByNameIgnoreCase("MANAGER"))
                .orElseThrow(() -> new IllegalStateException("Manager account type is not configured"));
    }

    private Role resolveManagerRole() {
        return roleRepository.findByNameIgnoreCase("MANAGER")
                .orElseThrow(() -> new IllegalStateException("Manager role is not configured"));
    }

    private String normalizePhone(String rawPhone) {
        if (rawPhone == null) {
            return null;
        }
        String digits = rawPhone.replaceAll("\\D", "");
        if (digits.length() == 11 && digits.startsWith("8")) {
            digits = "7" + digits.substring(1);
        }
        if (digits.length() == 10) {
            digits = "7" + digits;
        }
        if (digits.length() != 11 || !digits.startsWith("7")) {
            return null;
        }
        return "+" + digits.charAt(0) + digits.substring(1);
    }

    private String generatePassword() {
        String alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder builder = new StringBuilder();
        java.security.SecureRandom random = new java.security.SecureRandom();
        for (int i = 0; i < 8; i++) {
            builder.append(alphabet.charAt(random.nextInt(alphabet.length())));
        }
        return builder.toString();
    }

    private String trim(String value, String fallback) {
        String trimmed = trimNullable(value);
        if (trimmed != null) {
            return trimmed;
        }
        return fallback != null ? fallback.trim() : null;
    }

    private String trimNullable(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String resolveOwnerName(OwnerProfile owner) {
        String name = trimNullable(owner.getContactPerson());
        if (name != null) {
            return name;
        }
        name = trimNullable(owner.getLegalName());
        if (name != null) {
            return name;
        }
        if (owner.getUser() != null) {
            return owner.getUser().getPhone();
        }
        return "Owner";
    }
}
