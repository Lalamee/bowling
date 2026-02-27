package ru.bowling.bowlingapp.integration.onec.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import ru.bowling.bowlingapp.integration.onec.config.OneCIntegrationProperties;
import ru.bowling.bowlingapp.integration.onec.dto.OneCProductDto;
import ru.bowling.bowlingapp.integration.onec.dto.OneCStockItemDto;
import ru.bowling.bowlingapp.integration.onec.dto.OneCStockResponseDto;
import ru.bowling.bowlingapp.integration.onec.exception.OneCClientException;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;

@Component
public class OneCRestClient implements OneCClient {

    private static final Logger log = LoggerFactory.getLogger(OneCRestClient.class);

    private final OneCIntegrationProperties properties;
    private final RestTemplate restTemplate;

    public OneCRestClient(OneCIntegrationProperties properties) {
        this.properties = properties;
        this.restTemplate = new RestTemplate(requestFactory(properties));
    }

    @Override
    public List<OneCStockItemDto> importStockBalances() {
        String url = absoluteUrl(properties.getStockEndpoint());
        try {
            ResponseEntity<OneCStockResponseDto> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    new HttpEntity<>(authorizedHeaders()),
                    OneCStockResponseDto.class
            );
            OneCStockResponseDto body = response.getBody();
            if (body == null || body.getItems() == null) {
                return Collections.emptyList();
            }
            return body.getItems();
        } catch (RestClientException ex) {
            throw new OneCClientException("Не удалось получить остатки из 1С", ex);
        }
    }

    @Override
    public void exportProducts(List<OneCProductDto> products) {
        String url = absoluteUrl(properties.getProductsEndpoint());
        try {
            restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    new HttpEntity<>(products, authorizedHeaders()),
                    Void.class
            );
            log.info("Exported {} products to 1C", products != null ? products.size() : 0);
        } catch (RestClientException ex) {
            throw new OneCClientException("Не удалось экспортировать товары в 1С", ex);
        }
    }



    private SimpleClientHttpRequestFactory requestFactory(OneCIntegrationProperties properties) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        int timeout = properties.getTimeoutMs() != null ? properties.getTimeoutMs() : 10000;
        factory.setConnectTimeout(timeout);
        factory.setReadTimeout(timeout);
        return factory;
    }

    private HttpHeaders authorizedHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (properties.getUsername() != null && properties.getPassword() != null) {
            headers.setBasicAuth(properties.getUsername(), properties.getPassword(), StandardCharsets.UTF_8);
        }
        return headers;
    }

    private String absoluteUrl(String path) {
        String base = properties.getBaseUrl();
        if (base == null || base.isBlank()) {
            throw new OneCClientException("Не задан integration.onec.base-url");
        }
        if (path == null || path.isBlank()) {
            return base;
        }
        boolean baseSlash = base.endsWith("/");
        boolean pathSlash = path.startsWith("/");
        if (baseSlash && pathSlash) {
            return base + path.substring(1);
        }
        if (!baseSlash && !pathSlash) {
            return base + "/" + path;
        }
        return base + path;
    }
}
