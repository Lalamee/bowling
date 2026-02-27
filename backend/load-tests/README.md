# Нагрузочное тестирование (k6)

Скрипт: `load-tests/k6-scenarios.js`.

## Что покрывается

1. **Массовая авторизация** (`massive_auth`) — `POST /api/auth/login`.
2. **Массовые запросы к бизнес API** (`business_api_burst`) — `GET /api/parts/all`.
3. **Шторм уведомлений** (`notifications_storm`) — `POST /api/public/ws/notifications/broadcast`.

## Метрики

* `throughput` и `RPS` — в стандартном отчёте k6 (`http_reqs`, requests/s).
* `latency` — `http_req_duration` + кастомные тренды:
  * `auth_latency_ms`
  * `business_latency_ms`
  * `notification_latency_ms`
* **Поведение при деградации** — `degraded_responses_rate`:
  * учитываются ответы `5xx`
  * или ответы медленнее `1500ms`.

Пороговые значения зашиты в `options.thresholds`.

## Запуск

```bash
# 1) поднять backend локально
./gradlew bootRun

# 2) в отдельном терминале выполнить тест
k6 run load-tests/k6-scenarios.js

# при необходимости указать target
BASE_URL=http://localhost:8080 k6 run load-tests/k6-scenarios.js
```

## Интерпретация

* Нормальный режим: `http_req_failed < 5%`, `p95` по latency < 1.2s.
* Деградация: рост `degraded_responses_rate` > 10% и/или увеличение `p95` выше порогов.
* Для CI/регрессий рекомендуется сохранять артефакты k6 (`--summary-export`).
