package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.ClubStaffMemberDTO;
import ru.bowling.bowlingapp.DTO.CreateStaffRequestDTO;
import ru.bowling.bowlingapp.DTO.CreateStaffResponseDTO;
import ru.bowling.bowlingapp.Entity.*;
import ru.bowling.bowlingapp.Repository.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
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

    private enum StaffRole {
        MANAGER,
        MECHANIC
    }

    private static final long ACCOUNT_TYPE_MECHANIC_ID = 4L;
    private static final long ACCOUNT_TYPE_HEAD_MECHANIC_ID = 6L;

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
    public CreateStaffResponseDTO createStaff(Long clubId, CreateStaffRequestDTO request, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        StaffRole staffRole = resolveStaffRole(request.getRole());
        String normalizedPhone = normalizePhone(request.getPhone());
        if (normalizedPhone == null) {
            throw new IllegalArgumentException("Invalid phone format");
        }

        ensurePhoneAvailable(normalizedPhone);

        String rawPassword = resolvePassword(request.getPassword());

        return switch (staffRole) {
            case MANAGER -> createManagerStaff(club, request, normalizedPhone, rawPassword);
            case MECHANIC -> createMechanicStaff(club, request, normalizedPhone, rawPassword);
        };
    }

    private CreateStaffResponseDTO createManagerStaff(
            BowlingClub club,
            CreateStaffRequestDTO request,
            String normalizedPhone,
            String rawPassword
    ) {
        AccountType accountType = resolveManagerAccountType();
        Role role = resolveManagerRole();

        User user = prepareUser(normalizedPhone, rawPassword, role, accountType);

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

        return buildResponse(user, profile.getFullName(), rawPassword, role, club);
    }

    private CreateStaffResponseDTO createMechanicStaff(
            BowlingClub club,
            CreateStaffRequestDTO request,
            String normalizedPhone,
            String rawPassword
    ) {
        AccountType accountType = resolveMechanicAccountType();
        Role role = resolveMechanicRole();

        User user = prepareUser(normalizedPhone, rawPassword, role, accountType);

        MechanicProfile profile = MechanicProfile.builder()
                .user(user)
                .fullName(trim(request.getFullName(), normalizedPhone))
                .isEntrepreneur(false)
                .isDataVerified(false)
                .createdAt(LocalDate.now())
                .updatedAt(LocalDate.now())
                .workPlaces(club.getName())
                .build();

        List<BowlingClub> clubs = new ArrayList<>();
        clubs.add(club);
        profile.setClubs(clubs);

        user.setMechanicProfile(profile);
        userRepository.save(user);

        return buildResponse(user, profile.getFullName(), rawPassword, role, club);
    }

    private User prepareUser(String phone, String rawPassword, Role role, AccountType accountType) {
        return User.builder()
                .phone(phone)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .role(role)
                .registrationDate(LocalDate.now())
                .isActive(true)
                .isVerified(false)
                .accountType(accountType)
                .build();
    }

    private CreateStaffResponseDTO buildResponse(User user, String fullName, String rawPassword, Role role, BowlingClub club) {
        return CreateStaffResponseDTO.builder()
                .userId(user.getUserId())
                .fullName(trim(fullName, user.getPhone()))
                .phone(user.getPhone())
                .password(rawPassword)
                .role(role != null ? role.getName() : null)
                .clubId(club.getClubId())
                .clubName(club.getName())
                .build();
    }

    private StaffRole resolveStaffRole(String role) {
        if (role == null) {
            return StaffRole.MANAGER;
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        if (normalized.contains("MANAGER") || normalized.contains("МЕНЕДЖ")) {
            return StaffRole.MANAGER;
        }
        if (normalized.contains("MECHANIC") || normalized.contains("МЕХАН")) {
            return StaffRole.MECHANIC;
        }
        throw new IllegalArgumentException("Unsupported role: " + role);
    }

    private void ensurePhoneAvailable(String normalizedPhone) {
        if (userRepository.existsByPhone(normalizedPhone)) {
            throw new IllegalArgumentException("Phone already registered");
        }
    }

    private String resolvePassword(String candidate) {
        return Optional.ofNullable(candidate)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .orElseGet(this::generatePassword);
    }

    private User findUserByLogin(String login) {
        if (login == null || login.isBlank()) {
            return null;
        }
        String normalized = normalizePhone(login);
        if (normalized != null) {
            return userRepository.findByPhone(normalized).orElseGet(() -> userRepository.findByPhone(login).orElse(null));
        }
        return userRepository.findByPhone(login).orElse(null);
    }

    private void ensureClubAccess(BowlingClub club, User user) {
        if (club == null || user == null) {
            return;
        }
        if (hasRole(user, "ADMIN")) {
            return;
        }
        OwnerProfile owner = club.getOwner();
        if (owner == null || owner.getUser() == null) {
            throw new IllegalArgumentException("Club has no owner assigned");
        }
        if (!owner.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("You do not have access to manage this club");
        }
    }

    private boolean hasRole(User user, String roleName) {
        if (user == null || user.getRole() == null || roleName == null) {
            return false;
        }
        return roleName.equalsIgnoreCase(user.getRole().getName());
    }

    private AccountType resolveManagerAccountType() {
        return resolveAccountType(ACCOUNT_TYPE_HEAD_MECHANIC_ID,
                "HEAD_MECHANIC",
                "MANAGER",
                "Менеджер");
    }

    private Role resolveManagerRole() {
        return roleRepository.findByNameIgnoreCase("MANAGER")
                .orElseThrow(() -> new IllegalStateException("Manager role is not configured"));
    }

    private AccountType resolveMechanicAccountType() {
        return resolveAccountType(ACCOUNT_TYPE_MECHANIC_ID,
                "MECHANIC",
                "Механик");
    }

    private AccountType resolveAccountType(long id, String... fallbackNames) {
        Optional<AccountType> accountType = accountTypeRepository.findById(id);
        if (accountType.isPresent()) {
            return accountType.get();
        }
        if (fallbackNames != null) {
            for (String name : fallbackNames) {
                if (name == null) {
                    continue;
                }
                Optional<AccountType> byName = accountTypeRepository.findByNameIgnoreCase(name);
                if (byName.isPresent()) {
                    return byName.get();
                }
            }
        }
        throw new IllegalStateException("Account type not configured for id=" + id);
    }

    private Role resolveMechanicRole() {
        return roleRepository.findByNameIgnoreCase("MECHANIC")
                .orElseThrow(() -> new IllegalStateException("Mechanic role is not configured"));
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
