# Интеграция склада с 1С

Реализована интеграция с **типовым HTTP-сервисом 1С (REST/OData-подобный обмен)**.

## Поддержанные сценарии

1. **Экспорт товаров в 1С**
   - `POST {integration.onec.base-url}{integration.onec.products-endpoint}`
   - передается список каталожных позиций (`catalogNumber`, `nameRu`, `nameEn`, `description`).

2. **Импорт товаров/остатков из 1С**
   - `GET {integration.onec.base-url}{integration.onec.stock-endpoint}`
   - ожидается JSON-ответ вида:

```json
{
  "items": [
    {
      "catalogNumber": "ABC-123",
      "warehouseId": 10,
      "quantity": 25,
      "reservedQuantity": 3,
      "location": "A-01"
    }
  ]
}
```

3. **Синхронизация остатков**
   - сервис выполняет экспорт каталога, затем импорт остатков и upsert в `warehouse_inventory`.

## Retry / ошибки

- Для вызовов в 1С добавлена retry-стратегия:
  - `integration.onec.retry-attempts`
  - `integration.onec.retry-delay-ms`
- Ошибки клиента поднимаются как `OneCClientException`, ошибки процесса синхронизации — `OneCSyncException`.
- Для ручного запуска синхронизации endpoint возвращает `502` и последний статус при сбое.

## Endpoint'ы backend

- `POST /api/inventory/1c/sync` — ручная синхронизация.
- `GET /api/inventory/1c/sync/status` — последний статус синхронизации.

## Планировщик

- Scheduled sync включена в `core-service` через `@EnableScheduling`.
- Cron настраивается свойством `integration.onec.sync-cron`.

## Примечание про SOAP

В текущей реализации используется REST-интеграция (типовой и наиболее распространенный путь для обмена с 1С через HTTP-сервисы). При необходимости можно добавить SOAP-адаптер, сохранив тот же `OneCClient` интерфейс.
