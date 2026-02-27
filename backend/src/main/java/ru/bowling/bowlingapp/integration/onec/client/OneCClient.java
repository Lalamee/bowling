package ru.bowling.bowlingapp.integration.onec.client;

import ru.bowling.bowlingapp.integration.onec.dto.OneCProductDto;
import ru.bowling.bowlingapp.integration.onec.dto.OneCStockItemDto;

import java.util.List;

public interface OneCClient {
    List<OneCStockItemDto> importStockBalances();

    void exportProducts(List<OneCProductDto> products);
}
