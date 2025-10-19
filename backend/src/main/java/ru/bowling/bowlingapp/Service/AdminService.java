package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Repository.UserRepository;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;

    @Transactional
    public void verifyUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setIsVerified(true);
        if (user.getMechanicProfile() != null) {
            user.getMechanicProfile().setIsDataVerified(true);
        }
        if (user.getOwnerProfile() != null) {
            user.getOwnerProfile().setIsDataVerified(true);
        }
        userRepository.save(user);
    }

    @Transactional
    public void setUserActiveStatus(Long userId, boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setIsActive(isActive);
        userRepository.save(user);
    }

    @Transactional
    public void rejectRegistration(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found");
        }
        // Простое удаление пользователя. В реальной системе здесь может быть логирование, уведомление и т.д.
        userRepository.deleteById(userId);
    }
}
