package ru.bowling.bowlingapp.integration.onec.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "integration.onec")
public class OneCIntegrationProperties {

    private boolean enabled = false;
    private String baseUrl;
    private String stockEndpoint = "/hs/warehouse/v1/stocks";
    private String productsEndpoint = "/hs/warehouse/v1/products";
    private String username;
    private String password;
    private Integer timeoutMs = 10000;
    private Integer retryAttempts = 3;
    private Long retryDelayMs = 800L;
    private String syncCron = "0 */30 * * * *";
}
