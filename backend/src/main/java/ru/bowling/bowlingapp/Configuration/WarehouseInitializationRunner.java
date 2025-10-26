package ru.bowling.bowlingapp.Configuration;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import ru.bowling.bowlingapp.Service.ClubWarehouseService;

@Component
@Slf4j
@RequiredArgsConstructor
public class WarehouseInitializationRunner implements ApplicationRunner {

    private final ClubWarehouseService clubWarehouseService;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        try {
            clubWarehouseService.initializeAllClubWarehouses();
        } catch (Exception ex) {
            log.error("Failed to initialize club warehouses", ex);
            throw ex;
        }
    }
}

