package ru.bowling.bowlingapp.integration.onec.service;

import ru.bowling.bowlingapp.integration.onec.dto.OneCSyncStatusDto;

public interface OneCSyncService {

    OneCSyncStatusDto runManualSync();

    OneCSyncStatusDto getLastStatus();
}
