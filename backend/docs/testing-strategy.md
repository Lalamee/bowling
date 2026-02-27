# Стратегия автотестов

## Unit tests

Покрывают:

* сервисы (`src/test/java/ru/bowling/bowlingapp/Service/**`)
* security (`JwtTokenFilterTest`)
* JWT (`JwtTokenProviderTest`)
* 1С интеграцию (`OneCIntegrationServiceTest`)
* notification logic (`NotificationServiceTest`, `NotificationServiceAudienceTest`)

## Integration tests

Покрывают:

* REST endpoints (контроллеры + интеграционные сценарии)
* security flow (`SecurityFlowIntegrationTest`)
* auth + core взаимодействие (существующие интеграционные флоу + auth тесты)

## Testcontainers

* PostgreSQL контейнер используется в `OneCIntegrationServicePostgresTest`.
* Базовый класс: `integration/support/PostgresContainerBase`.
* В CI запуск обеспечивается workflow `.github/workflows/backend-tests.yml`.

## Проверка покрытия

Используется `JaCoCo` с порогом не ниже **80%** по instructions coverage.

Запуск локально:

```bash
cd backend
./gradlew clean test jacocoTestReport jacocoTestCoverageVerification
```
