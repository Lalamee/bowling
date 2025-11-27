package ru.bowling.bowlingapp.Service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.DTO.ClubStaffMemberDTO;
import ru.bowling.bowlingapp.DTO.CreateStaffRequestDTO;
import ru.bowling.bowlingapp.DTO.CreateStaffResponseDTO;
import ru.bowling.bowlingapp.Entity.AccountType;
import ru.bowling.bowlingapp.Entity.AdministratorProfile;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.ClubStaff;
import ru.bowling.bowlingapp.Entity.ManagerProfile;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Repository.AccountTypeRepository;
import ru.bowling.bowlingapp.Repository.AdministratorProfileRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.ManagerProfileRepository;
import ru.bowling.bowlingapp.Repository.MechanicProfileRepository;
import ru.bowling.bowlingapp.Repository.RoleRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ClubStaffService {

    private final BowlingClubRepository bowlingClubRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AccountTypeRepository accountTypeRepository;
    private final ManagerProfileRepository managerProfileRepository;
    private final AdministratorProfileRepository administratorProfileRepository;
    private final MechanicProfileRepository mechanicProfileRepository;
    private final ClubStaffRepository clubStaffRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @PersistenceContext
    private EntityManager entityManager;

    private enum StaffRole {
        MANAGER,
        MECHANIC,
        ADMINISTRATOR
    }

    private static final long ACCOUNT_TYPE_INDIVIDUAL_ID = 1L;
    private static final long ROLE_ADMIN_ID = 1L;
    private static final long ROLE_MECHANIC_ID = 4L;
    private static final long ROLE_HEAD_MECHANIC_ID = 6L;
    private static final long MIN_MECHANIC_USER_ID = 55L;
    private static final String ADMINISTRATOR_USER_FK_NAME = "fkdo5txam8feukemar3fh6cw1ue";
    private static final String ADMINISTRATOR_CLUB_FK_NAME = "fko1d0ydt7dsb15o2aelngsr374";

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
            StaffRole managerRole = determineManagerStaffRole(managerUser);
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(managerUser != null ? managerUser.getUserId() : null)
                    .fullName(trim(manager.getFullName(), managerUser != null ? managerUser.getPhone() : null))
                    .phone(manager.getContactPhone() != null ? manager.getContactPhone() : (managerUser != null ? managerUser.getPhone() : null))
                    .email(manager.getContactEmail())
                    .role(staffRoleToResponse(managerRole, managerUser != null ? managerUser.getRole() : null))
                    .isActive(resolveStaffActiveStatus(club, managerUser, managerUser != null ? managerUser.getIsActive() : Boolean.TRUE))
                    .build());
        }

        List<AdministratorProfile> administrators = administratorProfileRepository.findByClub_ClubId(clubId);
        for (AdministratorProfile administrator : administrators) {
            User administratorUser = administrator.getUser();
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(administratorUser != null ? administratorUser.getUserId() : null)
                    .fullName(trim(administrator.getFullName(), administratorUser != null ? administratorUser.getPhone() : null))
                    .phone(administrator.getContactPhone() != null ? administrator.getContactPhone() : (administratorUser != null ? administratorUser.getPhone() : null))
                    .email(administrator.getContactEmail())
                    .role(staffRoleToResponse(StaffRole.ADMINISTRATOR, administratorUser != null ? administratorUser.getRole() : null))
                    .isActive(resolveStaffActiveStatus(club, administratorUser, administratorUser != null ? administratorUser.getIsActive() : Boolean.TRUE))
                    .build());
        }

        List<MechanicProfile> mechanics = mechanicProfileRepository.findByClubs_ClubId(clubId);
        for (MechanicProfile mechanic : mechanics) {
            User mechanicUser = mechanic.getUser();
            ClubStaff clubStaff = mechanicUser != null
                    ? clubStaffRepository.findByClubAndUser(club, mechanicUser).orElse(null)
                    : null;
            staff.add(ClubStaffMemberDTO.builder()
                    .userId(mechanicUser != null ? mechanicUser.getUserId() : null)
                    .fullName(trim(mechanic.getFullName(), mechanicUser != null ? mechanicUser.getPhone() : null))
                    .phone(mechanicUser != null ? mechanicUser.getPhone() : null)
                    .role(staffRoleToResponse(StaffRole.MECHANIC, mechanicUser != null ? mechanicUser.getRole() : null))
                    .isActive(resolveStaffActiveStatus(club, mechanicUser, mechanicUser != null ? mechanicUser.getIsActive() : Boolean.TRUE))
                    // Передаем флаг, чтобы на фронте можно было ограничить доступ механика в рамках конкретного клуба
                    .accessRestricted(clubStaff != null && Boolean.TRUE.equals(clubStaff.getInfoAccessRestricted()))
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
            case MANAGER -> createManagerStaff(club, request, normalizedPhone, rawPassword, requestedBy);
            case MECHANIC -> createMechanicStaff(club, request, normalizedPhone, rawPassword, requestedBy);
            case ADMINISTRATOR -> createAdministratorStaff(club, request, normalizedPhone, rawPassword, requestedBy);
        };
    }

    @Transactional
    public void updateStaffStatus(Long clubId, Long userId, boolean active, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (isClubOwner(club, targetUser)) {
            throw new IllegalArgumentException("Club owner cannot change activation status");
        }

        ClubStaff clubStaff = clubStaffRepository.findByClubAndUser(club, targetUser)
                .orElseThrow(() -> new IllegalArgumentException("Staff member is not assigned to this club"));

        targetUser.setIsActive(active);
        targetUser.setIsVerified(active);
        userRepository.save(targetUser);

        MechanicProfile mechanicProfile = targetUser.getMechanicProfile();
        if (mechanicProfile != null) {
            mechanicProfile.setIsDataVerified(active);
            if (active) {
                mechanicProfile.setVerificationDate(LocalDate.now());
            }
            mechanicProfileRepository.save(mechanicProfile);
        }

        ManagerProfile managerProfile = targetUser.getManagerProfile();
        if (managerProfile != null) {
            managerProfile.setIsDataVerified(active);
            managerProfileRepository.save(managerProfile);
        }

        clubStaff.setIsActive(active);
        clubStaffRepository.save(clubStaff);
    }

    @Transactional
    public void updateMechanicAccessRestriction(Long clubId, Long userId, boolean restricted, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        MechanicProfile mechanicProfile = targetUser.getMechanicProfile();
        if (mechanicProfile == null) {
            throw new IllegalArgumentException("Target user is not a mechanic");
        }

        ClubStaff clubStaff = clubStaffRepository.findByClubAndUser(club, targetUser)
                .orElseThrow(() -> new IllegalArgumentException("Mechanic is not assigned to this club"));

        // Ограничиваем доступ только в рамках конкретного clubId
        clubStaff.setInfoAccessRestricted(restricted);
        clubStaffRepository.save(clubStaff);
    }

    @Transactional
    public void assignStaff(Long clubId, Long userId, String roleName, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (clubStaffRepository.existsByClubAndUser(club, targetUser)) {
            throw new IllegalArgumentException("User is already assigned to this club");
        }

        Role resolvedRole = resolveRoleForAssignment(roleName, targetUser);
        ClubStaff staff = ClubStaff.builder()
                .club(club)
                .user(targetUser)
                .role(resolvedRole)
                .isActive(Boolean.TRUE)
                .assignedAt(LocalDateTime.now())
                .assignedBy(requestedBy != null ? requestedBy.getUserId() : null)
                .build();

        clubStaffRepository.save(staff);
        targetUser.setRole(resolvedRole);
        userRepository.save(targetUser);
    }

    @Transactional
    public void removeStaff(Long clubId, Long userId, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (isClubOwner(club, user)) {
            throw new IllegalArgumentException("Club owner cannot be removed from staff");
        }

        clubStaffRepository.findByClubAndUser(club, user)
                .ifPresent(clubStaffRepository::delete);

        detachProfilesFromClub(club, user);
    }

    @Transactional
    public void updateStaffRole(Long clubId, Long userId, String roleName, String requestedByLogin) {
        BowlingClub club = bowlingClubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("Club not found"));

        User requestedBy = findUserByLogin(requestedByLogin);
        if (requestedBy != null) {
            ensureClubAccess(club, requestedBy);
        }

        ClubStaff staff = clubStaffRepository.findByClubAndUser(club,
                        userRepository.findById(userId)
                                .orElseThrow(() -> new IllegalArgumentException("User not found")))
                .orElseThrow(() -> new IllegalArgumentException("Staff member is not assigned to this club"));

        Role resolvedRole = resolveRoleForAssignment(roleName, staff.getUser());
        staff.setRole(resolvedRole);
        clubStaffRepository.save(staff);

        User user = staff.getUser();
        if (user != null) {
            user.setRole(resolvedRole);
            userRepository.save(user);
        }
    }

    private CreateStaffResponseDTO createManagerStaff(
            BowlingClub club,
            CreateStaffRequestDTO request,
            String normalizedPhone,
            String rawPassword,
            User requestedBy
    ) {
        AccountType accountType = resolveManagerAccountType();
        Role role = resolveManagerRole();

        User user = prepareUser(normalizedPhone, rawPassword, role, accountType);

        LocalDateTime now = LocalDateTime.now();

        ManagerProfile profile = ManagerProfile.builder()
                .fullName(trim(request.getFullName(), normalizedPhone))
                .contactPhone(normalizedPhone)
                .contactEmail(trimNullable(request.getEmail()))
                .isDataVerified(false)
                .createdAt(now)
                .updatedAt(now)
                .build();

        profile.setUser(user);
        profile.setClub(club);
        user.setManagerProfile(profile);

        userRepository.save(user);
        managerProfileRepository.save(profile);

        registerClubStaff(club, user, role, requestedBy);

        return buildResponse(user, profile.getFullName(), rawPassword, role, club, StaffRole.MANAGER);
    }

    private CreateStaffResponseDTO createMechanicStaff(
            BowlingClub club,
            CreateStaffRequestDTO request,
            String normalizedPhone,
            String rawPassword,
            User requestedBy
    ) {
        AccountType accountType = resolveMechanicAccountType();
        Role role = resolveMechanicRole();

        User user = prepareUser(normalizedPhone, rawPassword, role, accountType);

        ensureMechanicUserIdFloor();

        LocalDate today = LocalDate.now();

        MechanicProfile profile = MechanicProfile.builder()
                .fullName(trim(request.getFullName(), normalizedPhone))
                .isEntrepreneur(false)
                .isDataVerified(false)
                .createdAt(today)
                .updatedAt(today)
                .region(trimNullable(club.getAddress()))
                .build();

        List<BowlingClub> clubs = new ArrayList<>();
        clubs.add(club);
        profile.setClubs(clubs);

        profile.setUser(user);
        user.setMechanicProfile(profile);

        userRepository.save(user);
        mechanicProfileRepository.save(profile);

        registerClubStaff(club, user, role, requestedBy);

        return buildResponse(user, profile.getFullName(), rawPassword, role, club, StaffRole.MECHANIC);
    }

    private void ensureMechanicUserIdFloor() {
        if (entityManager == null) {
            return;
        }

        long maxUserId = getMaxColumnValue("users", "user_id");
        long maxMechanicUserId = getMaxColumnValue("mechanic_profiles", "user_id");

        long requiredFloor = Math.max(MIN_MECHANIC_USER_ID - 1, Math.max(maxUserId, maxMechanicUserId));

        adjustSequenceFloor("users", "user_id", requiredFloor);
    }

    private long getMaxColumnValue(String tableName, String columnName) {
        try {
            Object result = entityManager
                    .createNativeQuery(String.format(
                            "SELECT COALESCE(MAX(%s), 0) FROM %s",
                            columnName,
                            tableName
                    ))
                    .getSingleResult();
            if (result instanceof Number number) {
                return number.longValue();
            }
            if (result != null) {
                return Long.parseLong(result.toString());
            }
        } catch (Exception ignored) {
            // If the table is missing or inaccessible we silently ignore and fallback to zero.
        }
        return 0L;
    }

    private void adjustSequenceFloor(String tableName, String columnName, long floor) {
        if (floor < 0) {
            floor = 0;
        }

        try {
            Object sequenceNameResult = entityManager
                    .createNativeQuery(String.format(
                            "SELECT pg_get_serial_sequence('%s', '%s')",
                            tableName,
                            columnName
                    ))
                    .getSingleResult();

            if (sequenceNameResult == null) {
                return;
            }

            String sequenceName = sequenceNameResult.toString();
            if (sequenceName == null || sequenceName.isBlank()) {
                return;
            }

            Object[] sequenceState = (Object[]) entityManager
                    .createNativeQuery(String.format("SELECT last_value, is_called FROM %s", sequenceName))
                    .getSingleResult();

            long lastValue = 0L;
            boolean isCalled = true;
            if (sequenceState != null) {
                if (sequenceState.length > 0 && sequenceState[0] instanceof Number number) {
                    lastValue = number.longValue();
                } else if (sequenceState.length > 0 && sequenceState[0] != null) {
                    lastValue = Long.parseLong(sequenceState[0].toString());
                }
                if (sequenceState.length > 1 && sequenceState[1] != null) {
                    Object rawIsCalled = sequenceState[1];
                    if (rawIsCalled instanceof Boolean bool) {
                        isCalled = bool;
                    } else {
                        String textValue = rawIsCalled.toString();
                        isCalled = "t".equalsIgnoreCase(textValue)
                                || "true".equalsIgnoreCase(textValue)
                                || Boolean.parseBoolean(textValue);
                    }
                }
            }

            long target = Math.max(floor, lastValue);
            boolean shouldUpdate = target > lastValue || (!isCalled && target == lastValue);

            if (shouldUpdate) {
                entityManager
                        .createNativeQuery(String.format(
                                "SELECT setval('%s', %d, true)",
                                sequenceName,
                                target
                        ))
                        .getSingleResult();
            }
        } catch (Exception ignored) {
            // If sequence metadata cannot be accessed we avoid failing the whole operation.
        }
    }

    private CreateStaffResponseDTO createAdministratorStaff(
            BowlingClub club,
            CreateStaffRequestDTO request,
            String normalizedPhone,
            String rawPassword,
            User requestedBy
    ) {
        AccountType accountType = resolveAdministratorAccountType();
        Role role = resolveAdministratorRole();

        User user = prepareUser(normalizedPhone, rawPassword, role, accountType);

        User persistedUser = userRepository.save(user);

        ensureAdministratorForeignKeysTargetActiveTables();

        LocalDateTime now = LocalDateTime.now();

        AdministratorProfile profile = AdministratorProfile.builder()
                .fullName(trim(request.getFullName(), normalizedPhone))
                .contactPhone(normalizedPhone)
                .contactEmail(trimNullable(request.getEmail()))
                .isDataVerified(false)
                .createdAt(now)
                .updatedAt(now)
                .build();

        profile.setUser(persistedUser);
        profile.setClub(club);
        persistedUser.setAdministratorProfile(profile);

        administratorProfileRepository.save(profile);

        registerClubStaff(club, persistedUser, role, requestedBy);

        return buildResponse(persistedUser, profile.getFullName(), rawPassword, role, club, StaffRole.ADMINISTRATOR);
    }

    private void ensureAdministratorForeignKeysTargetActiveTables() {
        if (entityManager == null) {
            return;
        }

        ensureForeignKeyTargetsTable(
                "administrator_profiles",
                ADMINISTRATOR_USER_FK_NAME,
                "user_id",
                "users",
                "user_id"
        );

        ensureForeignKeyTargetsTable(
                "administrator_profiles",
                ADMINISTRATOR_CLUB_FK_NAME,
                "club_id",
                "bowling_clubs",
                "club_id"
        );
    }

    private void ensureForeignKeyTargetsTable(
            String sourceTable,
            String constraintName,
            String sourceColumn,
            String targetTable,
            String targetColumn
    ) {
        String referencedTable = null;
        try {
            Object result = entityManager
                    .createNativeQuery(
                            "SELECT r.relname FROM pg_constraint c " +
                                    "JOIN pg_class t ON c.conrelid = t.oid " +
                                    "JOIN pg_namespace tn ON tn.oid = t.relnamespace " +
                                    "JOIN pg_class r ON c.confrelid = r.oid " +
                                    "JOIN pg_namespace rn ON rn.oid = r.relnamespace " +
                                    "WHERE c.contype = 'f' " +
                                    "AND tn.nspname = current_schema() " +
                                    "AND c.conname = :constraint " +
                                    "AND t.relname = :table")
                    .setParameter("constraint", constraintName)
                    .setParameter("table", sourceTable)
                    .getSingleResult();
            if (result != null) {
                referencedTable = result.toString();
            }
        } catch (NoResultException ignored) {
            // The constraint does not exist – we'll recreate it below.
        } catch (Exception ex) {
            throw new IllegalStateException(
                    String.format("Failed to inspect foreign key %s on %s", constraintName, sourceTable),
                    ex
            );
        }

        if (referencedTable != null && targetTable.equalsIgnoreCase(referencedTable)) {
            return;
        }

        try {
            entityManager.createNativeQuery(
                            "ALTER TABLE " + sourceTable + " DROP CONSTRAINT IF EXISTS " + constraintName)
                    .executeUpdate();
        } catch (Exception ex) {
            throw new IllegalStateException(
                    String.format("Failed to drop foreign key %s on %s", constraintName, sourceTable),
                    ex
            );
        }

        try {
            entityManager.createNativeQuery(
                            "ALTER TABLE " + sourceTable +
                                    " ADD CONSTRAINT " + constraintName +
                                    " FOREIGN KEY (" + sourceColumn + ") REFERENCES " + targetTable +
                                    " (" + targetColumn + ")")
                    .executeUpdate();
        } catch (Exception ex) {
            throw new IllegalStateException(
                    String.format(
                            "Failed to recreate foreign key %s on %s referencing %s",
                            constraintName,
                            sourceTable,
                            targetTable
                    ),
                    ex
            );
        }
    }

    private void registerClubStaff(BowlingClub club, User user, Role role, User requestedBy) {
        if (club == null || user == null) {
            return;
        }

        ClubStaff clubStaff = clubStaffRepository.findByClubAndUser(club, user)
                .orElseGet(() -> ClubStaff.builder()
                        .club(club)
                        .user(user)
                        .assignedAt(LocalDateTime.now())
                        .build());

        clubStaff.setRole(role);
        clubStaff.setIsActive(Boolean.TRUE.equals(user.getIsActive()));
        if (clubStaff.getAssignedAt() == null) {
            clubStaff.setAssignedAt(LocalDateTime.now());
        }
        if (requestedBy != null) {
            clubStaff.setAssignedBy(requestedBy.getUserId());
        }

        clubStaffRepository.save(clubStaff);
    }

    private Boolean resolveStaffActiveStatus(BowlingClub club, User user, Boolean defaultValue) {
        if (user == null) {
            return defaultValue != null ? defaultValue : Boolean.TRUE;
        }

        return clubStaffRepository.findByClubAndUser(club, user)
                .map(ClubStaff::getIsActive)
                .filter(Objects::nonNull)
                .orElseGet(() -> {
                    Boolean userActive = user.getIsActive();
                    if (userActive != null) {
                        return userActive;
                    }
                    return defaultValue != null ? defaultValue : Boolean.TRUE;
                });
    }

    private boolean isClubOwner(BowlingClub club, User user) {
        if (club == null || user == null) {
            return false;
        }
        OwnerProfile owner = club.getOwner();
        return owner != null
                && owner.getUser() != null
                && Objects.equals(owner.getUser().getUserId(), user.getUserId());
    }

    private void detachProfilesFromClub(BowlingClub club, User user) {
        if (club == null || user == null || user.getUserId() == null) {
            return;
        }

        String normalizedRole = user.getRole() != null ? normalizeRoleName(user.getRole().getName()) : null;

        if (normalizedRole != null) {
            if (normalizedRole.contains("ADMIN")) {
                detachAdministratorFromClub(club, user.getUserId());
            }
            if (normalizedRole.contains("HEADMECHANIC") || normalizedRole.contains("MANAGER")) {
                detachManagerFromClub(club, user.getUserId());
            }
            if (normalizedRole.contains("MECHANIC")) {
                detachMechanicFromClub(club, user.getUserId());
            }
            return;
        }

        detachAdministratorFromClub(club, user.getUserId());
        detachManagerFromClub(club, user.getUserId());
        detachMechanicFromClub(club, user.getUserId());
    }

    private void detachAdministratorFromClub(BowlingClub club, Long userId) {
        administratorProfileRepository.findByUser_UserId(userId).ifPresent(profile -> {
            if (profile.getClub() != null && Objects.equals(profile.getClub().getClubId(), club.getClubId())) {
                profile.setClub(null);
                administratorProfileRepository.save(profile);
            }
        });
    }

    private void detachManagerFromClub(BowlingClub club, Long userId) {
        managerProfileRepository.findByUser_UserId(userId).ifPresent(profile -> {
            if (profile.getClub() != null && Objects.equals(profile.getClub().getClubId(), club.getClubId())) {
                profile.setClub(null);
                managerProfileRepository.save(profile);
            }
        });
    }

    private void detachMechanicFromClub(BowlingClub club, Long userId) {
        mechanicProfileRepository.findByUser_UserId(userId).ifPresent(profile -> {
            List<BowlingClub> clubs = Optional.ofNullable(profile.getClubs())
                    .map(ArrayList::new)
                    .orElseGet(ArrayList::new);
            boolean removed = clubs.removeIf(existingClub -> existingClub != null
                    && Objects.equals(existingClub.getClubId(), club.getClubId()));
            if (removed) {
                profile.setClubs(clubs);
                mechanicProfileRepository.save(profile);
            }
        });
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

    private CreateStaffResponseDTO buildResponse(User user, String fullName, String rawPassword, Role role, BowlingClub club, StaffRole staffRole) {
        return CreateStaffResponseDTO.builder()
                .userId(user.getUserId())
                .fullName(trim(fullName, user.getPhone()))
                .phone(user.getPhone())
                .password(rawPassword)
                .role(staffRoleToResponse(staffRole, role))
                .clubId(club.getClubId())
                .clubName(club.getName())
                .build();
    }

    private String staffRoleToResponse(StaffRole staffRole, Role role) {
        String result = null;
        if (staffRole != null) {
            result = switch (staffRole) {
                case MANAGER -> "MANAGER";
                case MECHANIC -> "MECHANIC";
                case ADMINISTRATOR -> "ADMIN";
            };
        } else if (role != null && role.getName() != null) {
            result = role.getName();
        }
        return mapRoleNameForResponse(result);
    }

    private StaffRole resolveStaffRole(String role) {
        if (role == null) {
            return StaffRole.MANAGER;
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        if (normalized.contains("HEAD_MECHANIC")
                || normalized.contains("MANAGER")
                || normalized.contains("ГЛАВНЫЙ")
                || normalized.contains("МЕНЕДЖ")) {
            return StaffRole.MANAGER;
        }
        if (normalized.contains("MECHANIC") || normalized.contains("МЕХАН")) {
            return StaffRole.MECHANIC;
        }
        if (normalized.contains("ADMIN") || normalized.contains("АДМИН")) {
            return StaffRole.ADMINISTRATOR;
        }
        throw new IllegalArgumentException("Unsupported role: " + role);
    }

    private StaffRole determineManagerStaffRole(User user) {
        if (user == null) {
            return StaffRole.MANAGER;
        }
        if (isAdministratorAccountType(user.getAccountType())
                || hasRole(user, "ADMINISTRATOR")
                || hasRole(user, "ADMIN")) {
            return StaffRole.ADMINISTRATOR;
        }
        if (hasRole(user, "HEAD_MECHANIC")
                || hasRole(user, "MANAGER")
                || isManagerAccountType(user.getAccountType())) {
            return StaffRole.MANAGER;
        }
        return StaffRole.MANAGER;
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
                .map(trimmed -> {
                    if (trimmed.length() < 6 || trimmed.length() > 32) {
                        throw new IllegalArgumentException("Password must be between 6 and 32 characters");
                    }
                    return trimmed;
                })
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
        if (owner != null && owner.getUser() != null
                && Objects.equals(owner.getUser().getUserId(), user.getUserId())) {
            return;
        }

        if (hasRole(user, "MANAGER") || hasRole(user, "HEAD_MECHANIC")) {
            ManagerProfile managerProfile = user.getManagerProfile();
            if (managerProfile != null && managerProfile.getClub() != null
                    && Objects.equals(managerProfile.getClub().getClubId(), club.getClubId())) {
                return;
            }
        }

        throw new IllegalArgumentException("You do not have access to manage this club");
    }

    private boolean hasRole(User user, String roleName) {
        if (user == null || user.getRole() == null || roleName == null) {
            return false;
        }
        return roleName.equalsIgnoreCase(user.getRole().getName());
    }

    private boolean isAdministratorAccountType(AccountType accountType) {
        if (accountType == null) {
            return false;
        }
        String normalized = normalizeAccountTypeName(accountType.getName());
        if (normalized == null) {
            return false;
        }
        return normalized.contains("ADMIN") || normalized.contains("АДМИН");
    }

    private boolean isManagerAccountType(AccountType accountType) {
        return matchesAccountType(accountType,
                ACCOUNT_TYPE_INDIVIDUAL_ID,
                "INDIVIDUAL",
                "HEAD_MECHANIC",
                "MANAGER",
                "Менеджер",
                "Главный механик",
                "Физическое лицо");
    }

    private AccountType resolveManagerAccountType() {
        AccountType specific = resolveAccountTypeByNames(
                "MANAGER",
                "HEAD_MECHANIC",
                "Главный механик",
                "Менеджер");
        if (specific != null) {
            return specific;
        }
        return resolveIndividualAccountType();
    }

    private Role resolveManagerRole() {
        return resolveRole(ROLE_HEAD_MECHANIC_ID,
                "HEAD_MECHANIC",
                "CHIEF_MECHANIC",
                "Главный механик");
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

    private AccountType resolveMechanicAccountType() {
        AccountType specific = resolveAccountTypeByNames(
                "MECHANIC",
                "Механик");
        if (specific != null) {
            return specific;
        }
        return resolveIndividualAccountType();
    }

    private Role resolveRoleForAssignment(String requestedRoleName, User targetUser) {
        if (requestedRoleName != null && !requestedRoleName.isBlank()) {
            Role role = findRoleByName(requestedRoleName);
            if (role == null) {
                role = createRoleIfMissing(requestedRoleName);
            }
            if (role != null) {
                return role;
            }
        }
        if (targetUser != null && targetUser.getRole() != null) {
            return targetUser.getRole();
        }
        throw new IllegalArgumentException("Role must be specified for staff assignment");
    }

    private AccountType resolveAccountType(long id, String... fallbackNames) {
        Optional<AccountType> accountType = accountTypeRepository.findById(id);
        if (accountType.isPresent() && matchesAccountType(accountType.get(), id, fallbackNames)) {
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

    private AccountType resolveAccountTypeByNames(String... names) {
        if (names == null || names.length == 0) {
            return null;
        }
        for (String name : names) {
            if (name == null) {
                continue;
            }
            String trimmed = name.trim();
            if (trimmed.isEmpty()) {
                continue;
            }
            Optional<AccountType> byName = accountTypeRepository.findByNameIgnoreCase(trimmed);
            if (byName.isPresent()) {
                return byName.get();
            }
        }
        return null;
    }

    private Role resolveMechanicRole() {
        return resolveRole(ROLE_MECHANIC_ID,
                "MECHANIC",
                "Механик");
    }

    private AccountType resolveAdministratorAccountType() {
        AccountType specific = resolveAccountTypeByNames(
                "ADMINISTRATOR",
                "ADMIN",
                "Администратор");
        if (specific != null) {
            return specific;
        }
        return resolveIndividualAccountType();
    }

    private AccountType resolveIndividualAccountType() {
        return accountTypeRepository.findById(ACCOUNT_TYPE_INDIVIDUAL_ID)
                .or(() -> accountTypeRepository.findByNameIgnoreCase("INDIVIDUAL"))
                .or(() -> accountTypeRepository.findByNameIgnoreCase("Физическое лицо"))
                .orElseThrow(() -> new IllegalStateException(
                        "Individual account type (id=" + ACCOUNT_TYPE_INDIVIDUAL_ID + ") is not configured"));
    }

    private Role resolveAdministratorRole() {
        return resolveRole(ROLE_ADMIN_ID,
                "ADMIN",
                "ADMINISTRATOR",
                "Администратор");
    }

    private Role resolveRole(long id, String... fallbackNames) {
        Optional<Role> role = roleRepository.findById(id);
        if (role.isPresent() && matchesRole(role.get(), id, fallbackNames)) {
            return role.get();
        }
        if (fallbackNames != null) {
            for (String name : fallbackNames) {
                Role byName = findRoleByName(name);
                if (byName != null) {
                    return byName;
                }
            }
            for (String name : fallbackNames) {
                Role created = createRoleIfMissing(name);
                if (created != null) {
                    return created;
                }
            }
        }
        throw new IllegalStateException("Role not configured for id=" + id);
    }

    private Role findRoleByName(String name) {
        if (name == null) {
            return null;
        }
        String trimmed = name.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return roleRepository.findByNameIgnoreCase(trimmed).orElse(null);
    }

    private Role createRoleIfMissing(String candidateName) {
        String normalized = normalizeRoleName(candidateName);
        if (normalized == null) {
            return null;
        }
        String trimmed = candidateName.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return roleRepository.findByNameIgnoreCase(trimmed)
                .orElseGet(() -> roleRepository.saveAndFlush(Role.builder().name(trimmed).build()));
    }

    private boolean matchesAccountType(AccountType accountType, long expectedId, String... names) {
        if (accountType == null) {
            return false;
        }
        Long accountTypeId = accountType.getAccountTypeId();
        if (accountTypeId != null && accountTypeId.longValue() == expectedId) {
            return true;
        }
        return matchesAccountTypeByName(accountType, names);
    }

    private boolean matchesAccountTypeByName(AccountType accountType, String... names) {
        if (accountType == null) {
            return false;
        }
        if (names == null || names.length == 0) {
            return true;
        }
        String actual = normalizeAccountTypeName(accountType.getName());
        if (actual == null) {
            return false;
        }
        for (String name : names) {
            String normalized = normalizeAccountTypeName(name);
            if (normalized != null && normalized.equals(actual)) {
                return true;
            }
        }
        return false;
    }

    private boolean matchesRole(Role role, long expectedId, String... names) {
        if (role == null) {
            return false;
        }
        Long roleId = role.getRoleId();
        if (roleId != null && roleId.longValue() == expectedId) {
            return true;
        }
        if (names == null || names.length == 0) {
            return true;
        }
        String actual = normalizeRoleName(role.getName());
        if (actual == null) {
            return false;
        }
        for (String name : names) {
            String normalized = normalizeRoleName(name);
            if (normalized != null && normalized.equals(actual)) {
                return true;
            }
        }
        return false;
    }

    private String normalizeRoleName(String value) {
        if (value == null) {
            return null;
        }
        return value.replaceAll("[\\s_\\-]", "").toUpperCase(Locale.ROOT);
    }

    private String normalizeAccountTypeName(String value) {
        if (value == null) {
            return null;
        }
        return value.replaceAll("[\\s_\\-]", "").toUpperCase(Locale.ROOT);
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
