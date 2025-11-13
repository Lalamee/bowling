package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.*;

import ru.bowling.bowlingapp.Entity.AdministratorProfile;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "phone", nullable = false, unique = true, length = 20)
    private String phone;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    private Role role;

    @Column(name = "registration_date", nullable = false)
    private LocalDate registrationDate;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_type_id", nullable = false)
    private AccountType accountType;

    @Version
    @Column(name = "version")
    private Long version;

    @Column(name = "last_modified")
    private LocalDateTime lastModified;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private MechanicProfile mechanicProfile;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private OwnerProfile ownerProfile;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private ManagerProfile managerProfile;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private AdministratorProfile administratorProfile;

    public String getFullName() {
        if (mechanicProfile != null && isNotBlank(mechanicProfile.getFullName())) {
            return mechanicProfile.getFullName().trim();
        }
        if (managerProfile != null && isNotBlank(managerProfile.getFullName())) {
            return managerProfile.getFullName().trim();
        }
        if (administratorProfile != null && isNotBlank(administratorProfile.getFullName())) {
            return administratorProfile.getFullName().trim();
        }
        if (ownerProfile != null) {
            if (isNotBlank(ownerProfile.getContactPerson())) {
                return ownerProfile.getContactPerson().trim();
            }
            if (isNotBlank(ownerProfile.getLegalName())) {
                return ownerProfile.getLegalName().trim();
            }
        }
        if (phone != null && !phone.isBlank()) {
            return phone.trim();
        }
        return null;
    }

    private boolean isNotBlank(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
