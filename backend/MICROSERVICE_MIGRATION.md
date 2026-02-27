# Миграция на 2 микросервиса

## Gradle multi-module
- `platform-common` — общая доменная модель, сервисы, репозитории, DTO, security-компоненты и интеграции.
- `auth-service` — отдельный Spring Boot модуль для `/api/auth/**`.
- `core-service` — отдельный Spring Boot модуль для бизнес-операций и доменных API.

## Новые сервисы

### auth-service
- `AuthController`
- `AuthService`
- регистрация, логин, refresh token, `/api/auth/me`
- security-конфигурация с `AuthenticationManager` и `DaoAuthenticationProvider`
- порт `8082`

### core-service
- вся доменная/бизнес-логика и REST API кроме `/api/auth/**`
- JWT валидация через `JwtTokenFilter` + `JwtTokenProvider`
- без логики аутентификации (нет `AuthService` в security цепочке)
- порт `8081`

## Единая БД
- Оба сервиса используют существующий datasource (`application.yml`)
- Схема и миграции не менялись

## JWT доверие
- Валидация токена в `core-service` выполняется с тем же `jwt.secret`
- `auth-service` отвечает за выпуск access/refresh токенов

## Профили запуска
- `dev/test/prod` в базовом `application.yml`
- `core` -> `application-core.yml`
- `auth` -> `application-auth.yml`

## Docker Compose
- `backend/docker-compose.yml` поднимает `auth-service` и `core-service`
- оба контейнера используют одну и ту же БД и JWT-конфигурацию
