package ru.bowling.bowlingapp.Exception;

public class InvalidRefreshTokenException extends RuntimeException {
        public InvalidRefreshTokenException(String message) {
                super(message);
        }
}
