package ru.bowling.bowlingapp.Exception;

import com.auth0.jwt.exceptions.JWTVerificationException;
import jakarta.persistence.EntityNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ValidationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

	private Map<String, Object> buildError(HttpServletRequest request, HttpStatus status, String code, String message) {
		Map<String, Object> body = new HashMap<>();
		body.put("timestamp", OffsetDateTime.now(ZoneOffset.UTC).toString());
		body.put("path", request.getRequestURI());
		body.put("status", status.value());
		body.put("code", code);
		body.put("message", message);
		return body;
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<Map<String, Object>> handleMethodArgumentNotValid(MethodArgumentNotValidException ex, HttpServletRequest request) {
		String message = ex.getBindingResult().getAllErrors().stream().findFirst()
				.map(err -> err.getDefaultMessage()).orElse("Validation failed");
		return ResponseEntity.status(HttpStatus.BAD_REQUEST)
				.body(buildError(request, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message));
	}

	@ExceptionHandler(ValidationException.class)
	public ResponseEntity<Map<String, Object>> handleValidation(ValidationException ex, HttpServletRequest request) {
		return ResponseEntity.status(HttpStatus.BAD_REQUEST)
				.body(buildError(request, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", ex.getMessage()));
	}

	@ExceptionHandler(EntityNotFoundException.class)
	public ResponseEntity<Map<String, Object>> handleNotFound(EntityNotFoundException ex, HttpServletRequest request) {
		return ResponseEntity.status(HttpStatus.NOT_FOUND)
				.body(buildError(request, HttpStatus.NOT_FOUND, "ENTITY_NOT_FOUND", ex.getMessage()));
	}

	@ExceptionHandler(AccessDeniedException.class)
	public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
		return ResponseEntity.status(HttpStatus.FORBIDDEN)
				.body(buildError(request, HttpStatus.FORBIDDEN, "ACCESS_DENIED", "Доступ запрещён"));
	}

        @ExceptionHandler(JWTVerificationException.class)
        public ResponseEntity<Map<String, Object>> handleJwt(JWTVerificationException ex, HttpServletRequest request) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                .body(buildError(request, HttpStatus.UNAUTHORIZED, "JWT_INVALID", "Недействительный или истёкший токен"));
        }

        @ExceptionHandler(InvalidRefreshTokenException.class)
        public ResponseEntity<Map<String, Object>> handleInvalidRefreshToken(InvalidRefreshTokenException ex, HttpServletRequest request) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                .body(buildError(request, HttpStatus.UNAUTHORIZED, "REFRESH_TOKEN_INVALID", ex.getMessage()));
        }

	@ExceptionHandler(IllegalArgumentException.class)
	public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest request) {
		return ResponseEntity.status(HttpStatus.BAD_REQUEST)
				.body(buildError(request, HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage()));
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex, HttpServletRequest request) {
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
				.body(buildError(request, HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Внутренняя ошибка сервера"));
	}
}

