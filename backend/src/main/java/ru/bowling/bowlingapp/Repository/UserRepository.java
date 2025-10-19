package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.User;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    boolean existsByPhone(String phone);
    Optional<User> findByPhone(String phone);
    Optional<User> findUserByUserId(Long userId);
}
