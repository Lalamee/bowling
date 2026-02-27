package ru.bowling.bowlingapp.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "ru.bowling.bowlingapp")
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(AuthServiceApplication.class);
        app.setAdditionalProfiles("auth");
        app.run(args);
    }
}
