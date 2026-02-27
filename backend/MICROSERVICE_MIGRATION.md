# Миграция на 2 микросервиса

## Новые сервисы

### auth-service
- `AuthController`
- `AuthService`
- регистрация, логин, refresh token, `/api/auth/me`
- security-конфигурация с `AuthenticationManager` и `DaoAuthenticationProvider`

### core-service
- вся доменная/бизнес-логика и REST API кроме `/api/auth/**`
- JWT валидация через `JwtTokenFilter` + `JwtTokenProvider`
- без логики аутентификации (нет `AuthService` в security цепочке)

## Единая БД
- Оба сервиса используют существующий datasource (`application.yml`)
- Схема и миграции не менялись

## JWT доверие
- Валидация токена в `core-service` выполняется с тем же `jwt.secret`
- `auth-service` отвечает только за выпуск access/refresh токенов

## Профили запуска
- `core` -> `application-core.yml`
- `auth` -> `application-auth.yml`
