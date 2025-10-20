package ru.bowling.bowlingapp.Controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.Config.JwtTokenProvider;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.MechanicProfile;
import ru.bowling.bowlingapp.Entity.OwnerProfile;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Repository.UserRepository;
import ru.bowling.bowlingapp.Service.AuthService;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", Pattern.CASE_INSENSITIVE);

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequestDTO request) {
        authService.registerUser(request.getUser(), request.getMechanicProfile(), request.getOwnerProfile());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(StandardResponseDTO.builder().message("User registered successfully").status("success").build());
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        Identifier identifier = resolveIdentifier(request.getIdentifier());
        if (identifier == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("code", "AUTH_IDENTIFIER_INVALID", "message", "Введите телефон +7XXXXXXXXXX или e-mail"));
        }

        Optional<User> userOptional = identifier.type == IdentifierType.PHONE
                ? userRepository.findByPhone(identifier.value)
                : userRepository.findByEmailIgnoreCase(identifier.value);

        if (userOptional.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("code", "AUTH_INVALID", "message", "Неверный логин или пароль"));
        }

        User user = userOptional.get();
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("code", "AUTH_INVALID", "message", "Неверный логин или пароль"));
        }

        if (user.getIsActive() != null && !user.getIsActive()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("code", "AUTH_INACTIVE", "message", "Аккаунт деактивирован"));
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);
        LoginResponseDTO response = LoginResponseDTO.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .user(buildUserSummary(user))
                .build();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@RequestBody RefreshTokenRequestDTO request) {
        String refreshToken = request.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(StandardResponseDTO.builder().message("Refresh token is required").status("error").build());
        }

        if (!jwtTokenProvider.isValidToken(refreshToken)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(StandardResponseDTO.builder().message("Invalid refresh token").status("error").build());
        }

        String phone = jwtTokenProvider.getPhoneFromToken(refreshToken);
        User user = authService.findUserByPhone(phone);

        if (!user.getIsActive()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(StandardResponseDTO.builder().message("Account is deactivated").status("error").build());
        }

        String newAccessToken = jwtTokenProvider.generateAccessToken(user);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user);
        LoginResponseDTO response = LoginResponseDTO.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .tokenType("Bearer")
                .user(buildUserSummary(user))
                .build();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        return ResponseEntity.ok(StandardResponseDTO.builder().message("Logged out successfully").status("success").build());
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
        }

        String phone = authentication.getName();
        User user = authService.findUserByPhone(phone);

        UserInfoDTO userInfo = UserInfoDTO.builder()
                .id(user.getUserId())
                .phone(user.getPhone())
                .roleId(user.getRole().getRoleId())
                .accountTypeId(user.getAccountType().getAccountTypeId())
                .isVerified(user.getIsVerified())
                .registrationDate(user.getRegistrationDate())
                .build();
        return ResponseEntity.ok(userInfo);
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@Valid @RequestBody PasswordChangeRequest request, Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
        }
        String phone = authentication.getName();
        authService.changePassword(phone, request.getOldPassword(), request.getNewPassword());
        return ResponseEntity.ok(StandardResponseDTO.builder().message("Password changed successfully").status("success").build());
    }

    private Identifier resolveIdentifier(String raw) {
        if (raw == null) {
            return null;
        }
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) {
            return null;
        }

        String normalizedPhone = normalizePhone(trimmed);
        if (normalizedPhone != null) {
            return new Identifier(normalizedPhone, IdentifierType.PHONE);
        }

        String normalizedEmail = normalizeEmail(trimmed);
        if (normalizedEmail != null) {
            return new Identifier(normalizedEmail, IdentifierType.EMAIL);
        }

        return null;
    }

    private String normalizePhone(String input) {
        String digits = input.replaceAll("\\D", "");
        if (digits.length() == 11 && digits.startsWith("8")) {
            digits = "7" + digits.substring(1);
        }
        if (digits.length() == 10) {
            return "+7" + digits;
        }
        if (digits.length() == 11 && digits.startsWith("7")) {
            return "+7" + digits.substring(1);
        }
        return null;
    }

    private String normalizeEmail(String input) {
        String email = input.trim();
        if (EMAIL_PATTERN.matcher(email).matches()) {
            return email.toLowerCase(Locale.ROOT);
        }
        return null;
    }

    private UserSummaryDTO buildUserSummary(User user) {
        String name = Optional.ofNullable(user.getMechanicProfile())
                .map(MechanicProfile::getFullName)
                .filter(s -> s != null && !s.trim().isEmpty())
                .or(() -> Optional.ofNullable(user.getOwnerProfile())
                        .map(OwnerProfile::getContactPerson)
                        .filter(s -> s != null && !s.trim().isEmpty()))
                .orElse(null);

        return UserSummaryDTO.builder()
                .id(user.getUserId())
                .role(user.getRole() != null ? user.getRole().getName() : null)
                .name(name)
                .email(user.getEmail())
                .phone(user.getPhone())
                .build();
    }

    private record Identifier(String value, IdentifierType type) {
    }

    private enum IdentifierType {
        PHONE,
        EMAIL
    }
}
