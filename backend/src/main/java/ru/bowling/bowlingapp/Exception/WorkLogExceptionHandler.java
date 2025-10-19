package ru.bowling.bowlingapp.Exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import ru.bowling.bowlingapp.DTO.StandardResponseDTO;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class WorkLogExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<StandardResponseDTO> handleValidationExceptions(MethodArgumentNotValidException ex) {
        BindingResult result = ex.getBindingResult();
        Map<String, String> errors = new HashMap<>();
        
        for (FieldError error : result.getFieldErrors()) {
            errors.put(error.getField(), error.getDefaultMessage());
        }

        log.warn("Validation errors: {}", errors);

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(StandardResponseDTO.builder()
                        .message("Validation failed: " + errors.toString())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<StandardResponseDTO> handleIllegalArgumentException(IllegalArgumentException ex) {
        log.warn("IllegalArgumentException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(WorkLogNotFoundException.class)
    public ResponseEntity<StandardResponseDTO> handleWorkLogNotFound(WorkLogNotFoundException ex) {
        log.warn("WorkLogNotFoundException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(ServiceHistoryNotFoundException.class)
    public ResponseEntity<StandardResponseDTO> handleServiceHistoryNotFound(ServiceHistoryNotFoundException ex) {
        log.warn("ServiceHistoryNotFoundException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(InvalidStatusTransitionException.class)
    public ResponseEntity<StandardResponseDTO> handleInvalidStatusTransition(InvalidStatusTransitionException ex) {
        log.warn("InvalidStatusTransitionException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(PartNotAvailableException.class)
    public ResponseEntity<StandardResponseDTO> handlePartNotAvailable(PartNotAvailableException ex) {
        log.warn("PartNotAvailableException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(UnauthorizedOperationException.class)
    public ResponseEntity<StandardResponseDTO> handleUnauthorizedOperation(UnauthorizedOperationException ex) {
        log.warn("UnauthorizedOperationException: {}", ex.getMessage());

        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(StandardResponseDTO.builder()
                        .message(ex.getMessage())
                        .status("error")
                        .build());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<StandardResponseDTO> handleGenericException(Exception ex) {
        log.error("Unexpected error: ", ex);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(StandardResponseDTO.builder()
                        .message("An unexpected error occurred")
                        .status("error")
                        .build());
    }
    
    public static class WorkLogNotFoundException extends RuntimeException {
        public WorkLogNotFoundException(String message) {
            super(message);
        }
        
        public WorkLogNotFoundException(Long id) {
            super("Work log with id " + id + " not found");
        }
    }

    public static class ServiceHistoryNotFoundException extends RuntimeException {
        public ServiceHistoryNotFoundException(String message) {
            super(message);
        }
        
        public ServiceHistoryNotFoundException(Long id) {
            super("Service history record with id " + id + " not found");
        }
    }

    public static class InvalidStatusTransitionException extends RuntimeException {
        public InvalidStatusTransitionException(String currentStatus, String newStatus) {
            super("Invalid status transition from " + currentStatus + " to " + newStatus);
        }
    }

    public static class PartNotAvailableException extends RuntimeException {
        public PartNotAvailableException(String partNumber, int requestedQuantity, int availableQuantity) {
            super("Part " + partNumber + " not available. Requested: " + requestedQuantity + ", Available: " + availableQuantity);
        }
    }

    public static class UnauthorizedOperationException extends RuntimeException {
        public UnauthorizedOperationException(String operation) {
            super("You are not authorized to perform this operation: " + operation);
        }
    }
}
