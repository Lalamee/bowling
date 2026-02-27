package ru.bowling.bowlingapp.core;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "ru.bowling.bowlingapp")
public class CoreServiceApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(CoreServiceApplication.class);
        app.setAdditionalProfiles("core", "dev");
        app.run(args);
    }
}
