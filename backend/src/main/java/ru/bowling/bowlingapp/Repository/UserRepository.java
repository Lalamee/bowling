package ru.bowling.bowlingapp.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.User;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    @EntityGraph(attributePaths = {
            "role",
            "accountType",
            "mechanicProfile",
            "mechanicProfile.clubs",
            "ownerProfile",
            "ownerProfile.clubs",
            "managerProfile",
            "managerProfile.club",
            "administratorProfile"
    })
    Page<User> findAllWithProfiles(Pageable pageable);

    boolean existsByPhone(String phone);
    Optional<User> findByPhone(String phone);
    Optional<User> findUserByUserId(Long userId);
}
