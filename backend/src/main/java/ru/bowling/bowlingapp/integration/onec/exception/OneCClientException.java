package ru.bowling.bowlingapp.integration.onec.exception;

public class OneCClientException extends RuntimeException {
    public OneCClientException(String message) {
        super(message);
    }

    public OneCClientException(String message, Throwable cause) {
        super(message, cause);
    }
}
