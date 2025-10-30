package ru.bowling.bowlingapp.Controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.Config.JwtTokenProvider;
import ru.bowling.bowlingapp.DTO.*;
import ru.bowling.bowlingapp.Entity.User;
import ru.bowling.bowlingapp.Service.AuthService;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequestDTO request) {
        authService.registerUser(
                request.getUser(),
                request.getMechanicProfile(),
                request.getOwnerProfile(),
                request.getManagerProfile(),
                request.getClub()
        );
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(StandardResponseDTO.builder().message("User registered successfully").status("success").build());
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody UserLoginDTO loginDto) {
        User user = authService.authenticateUser(loginDto.getPhone(), loginDto.getPassword());

        if (!user.getIsActive()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(StandardResponseDTO.builder().message("Account is deactivated").status("error").build());
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginDto.getPhone(), loginDto.getPassword())
            );
        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(StandardResponseDTO.builder().message("Invalid phone or password").status("error").build());
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);
        LoginResponseDTO response = new LoginResponseDTO(accessToken, refreshToken);
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
        LoginResponseDTO response = new LoginResponseDTO(newAccessToken, newRefreshToken);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        return ResponseEntity.ok(StandardResponseDTO.builder().message("Logged out successfully").status("success").build());
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(
            Authentication authentication,
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorizationHeader
    ) {
        Authentication resolvedAuth = authentication;

        if ((resolvedAuth == null || !resolvedAuth.isAuthenticated())
                && authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            String token = authorizationHeader.substring(7);
            try {
                resolvedAuth = jwtTokenProvider.getAuthentication(token);
                SecurityContextHolder.getContext().setAuthentication(resolvedAuth);
            } catch (Exception ignored) {
            }
        }

        if (resolvedAuth == null || !resolvedAuth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(StandardResponseDTO.builder().message("User not authenticated").status("error").build());
        }

        String login = resolvedAuth.getName();
        return ResponseEntity.ok(authService.getCurrentUserInfo(login));
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

//    @PostMapping("/reset-password/request")
//    public ResponseEntity<?> requestPasswordReset(@Valid @RequestBody PasswordResetInitRequestDTO request) {
//        authService.requestPasswordReset(request.getPhone());
//        return ResponseEntity.ok(StandardResponseDTO.builder().message("Reset token sent").status("success").build());
//    }
//
//    @PostMapping("/reset-password/confirm")
//    public ResponseEntity<?> confirmPasswordReset(@Valid @RequestBody PasswordResetConfirmRequestDTO request) {
//        authService.confirmPasswordReset(request.getToken(), request.getNewPassword());
//        return ResponseEntity.ok(StandardResponseDTO.builder().message("Password reset successfully").status("success").build());
//    }
}
