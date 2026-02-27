# Руководство по развертыванию - Bowling Manager

## 📋 Содержание

1. [Требования](#требования)
2. [Локальная разработка](#локальная-разработка)
3. [Production развертывание](#production-развертывание)
4. [Тестирование](#тестирование)
5. [Troubleshooting](#troubleshooting)

---

## Требования

### Backend
- **Java:** 17+
- **PostgreSQL:** 14+
- **Gradle:** 8+ (встроен в проект)
- **RAM:** минимум 512MB, рекомендуется 1GB+

### Frontend
- **Flutter:** 3.0.0+
- **Dart SDK:** 3.0.0+
- **Android SDK:** API 21+ (Android 5.0+)
- **iOS:** 11.0+ (для iOS сборки)

### Инструменты
- Git
- Docker (опционально)
- IDE: IntelliJ IDEA / VS Code / Android Studio

---

## Локальная разработка

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd bowling
```

### 2. Настройка Backend

#### 2.1. Установка PostgreSQL

**Windows:**
```bash
# Скачать с https://www.postgresql.org/download/windows/
# Или через Chocolatey:
choco install postgresql
```

**Linux:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

#### 2.2. Создание базы данных

```bash
# Подключение к PostgreSQL
psql -U postgres

# Создание БД и пользователя
CREATE DATABASE bowling_db;
CREATE USER bowling_user WITH PASSWORD 'bowling_pass';
GRANT ALL PRIVILEGES ON DATABASE bowling_db TO bowling_user;
\q
```

#### 2.3. Настройка переменных окружения

Создайте файл `.env` в корне проекта:

```env
# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/bowling_db
SPRING_DATASOURCE_USERNAME=bowling_user
SPRING_DATASOURCE_PASSWORD=bowling_pass

# JWT
JWT_SECRET=your-super-secret-jwt-key-that-should-be-at-least-256-bits-long-for-security-please-change-in-production
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081,http://10.0.2.2:8080
```

#### 2.4. Запуск Backend (микросервисы)

```bash
cd backend

# Core service (бизнес-логика + API)
./gradlew bootRun --args='--spring.profiles.active=core'

# Auth service (регистрация/логин/JWT)
./gradlew bootRun --args='--spring.profiles.active=auth --server.port=8082'
```

- `core-service`: `http://localhost:8081`
- `auth-service`: `http://localhost:8082`
- Оба сервиса используют одну PostgreSQL БД и общий `JWT_SECRET`.

**Swagger UI:**
- `core-service`: `http://localhost:8081/swagger-ui/index.html`
- `auth-service`: `http://localhost:8082/swagger-ui/index.html`

### 3. Настройка Frontend

#### 3.1. Установка зависимостей

```bash
cd frontend
flutter pub get
```

#### 3.2. Настройка .env

Создайте файл `frontend/.env`:

```env
# Для локальной разработки
API_URL=http://localhost:8080

# Для Android эмулятора
# API_URL=http://10.0.2.2:8080

# Для iOS симулятора
# API_URL=http://localhost:8080
```

#### 3.3. Запуск Flutter приложения

**Desktop (Windows/Linux/macOS):**
```bash
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d macos    # macOS
```

**Web:**
```bash
flutter run -d chrome --web-port=8081
```

**Android:**
```bash
# Запустите Android эмулятор
flutter emulators --launch <emulator_id>

# Запустите приложение
flutter run
```

**iOS (только macOS):**
```bash
# Откройте iOS симулятор
open -a Simulator

# Запустите приложение
flutter run
```

---

## Production развертывание

### Backend (Spring Boot)

#### Вариант 1: JAR файл

```bash
cd backend

# Сборка
./gradlew clean build -x test

# Запуск
java -jar build/libs/bowling-app-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=prod \
  --spring.datasource.url=jdbc:postgresql://your-db-host:5432/bowling_db \
  --spring.datasource.username=your_user \
  --spring.datasource.password=your_password \
  --jwt.secret=your-production-secret
```

#### Вариант 2: Docker

Создайте `backend/Dockerfile`:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
COPY src src
RUN ./gradlew clean build -x test

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Сборка и запуск:

```bash
# Сборка образа
docker build -t bowling-backend:latest .

# Запуск контейнера
docker run -d \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/bowling_db \
  -e SPRING_DATASOURCE_USERNAME=bowling_user \
  -e SPRING_DATASOURCE_PASSWORD=bowling_pass \
  -e JWT_SECRET=your-production-secret \
  --name bowling-backend \
  bowling-backend:latest
```

#### Вариант 3: Docker Compose

Используйте `backend/docker-compose.yml`:

```bash
cd backend
docker-compose up -d
```

### Frontend (Flutter)

#### Android APK

```bash
cd frontend

# Debug сборка
flutter build apk --debug

# Release сборка
flutter build apk --release

# Split APKs по архитектуре (меньший размер)
flutter build apk --split-per-abi --release
```

APK файлы будут в `build/app/outputs/flutter-apk/`

#### Android App Bundle (для Google Play)

```bash
flutter build appbundle --release
```

AAB файл будет в `build/app/outputs/bundle/release/`

#### iOS (требуется macOS + Xcode)

```bash
# Открыть Xcode
open ios/Runner.xcworkspace

# Или через командную строку
flutter build ios --release
```

#### Web

```bash
flutter build web --release
```

Файлы будут в `build/web/`

Разверните на любом веб-сервере (Nginx, Apache, Firebase Hosting, Vercel, etc.)

---

## Конфигурация Production

### Backend application.yml (production profile)

```yaml
spring:
  config:
    activate:
      on-profile: prod
  
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
  
  jpa:
    hibernate:
      ddl-auto: validate  # Важно! Не используйте update в production
    show-sql: false

  web:
    cors:
      allowed-origins: ${CORS_ALLOWED_ORIGINS}

server:
  port: 8080
  compression:
    enabled: true

jwt:
  secret: ${JWT_SECRET}
  access:
    expiration: 3600000
  refresh:
    expiration: 604800000

logging:
  level:
    root: INFO
    ru.bowling: INFO
```

### Frontend production .env

```env
API_URL=https://api.yourdomain.com
```

### Nginx конфигурация (для backend)

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL/HTTPS (Let's Encrypt)

```bash
# Установка certbot
sudo apt install certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d api.yourdomain.com

# Автообновление
sudo certbot renew --dry-run
```

---

## Тестирование

### Backend тесты

```bash
cd backend

# Запуск всех тестов
./gradlew test

# Запуск с отчетом покрытия
./gradlew test jacocoTestReport

# Отчет будет в build/reports/tests/test/index.html
```

### Frontend тесты

```bash
cd frontend

# Unit тесты
flutter test

# Integration тесты
flutter test integration_test

# Покрытие кода
flutter test --coverage
```

### API тестирование (Postman/cURL)

**Пример: Авторизация**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+79001234567",
    "password": "password123"
  }'
```

**Пример: Получение пользователя**
```bash
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Мониторинг и логирование

### Backend логи

Логи Spring Boot по умолчанию выводятся в консоль. Для production настройте `logback-spring.xml`:

```xml
<configuration>
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/bowling-app.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/bowling-app.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

### Health Check

Backend предоставляет health endpoint (если включен Spring Actuator):

```bash
curl http://localhost:8080/actuator/health
```

---

## Troubleshooting

### Backend проблемы

#### 1. Ошибка подключения к БД

**Симптом:** `Connection refused` или `Authentication failed`

**Решение:**
```bash
# Проверьте статус PostgreSQL
sudo systemctl status postgresql

# Проверьте подключение
psql -U bowling_user -d bowling_db -h localhost

# Проверьте настройки в application.yml
```

#### 2. CORS ошибки

**Симптом:** `Access-Control-Allow-Origin` ошибка в браузере

**Решение:**
- Проверьте `WebConfig.java` - добавьте origin вашего frontend
- Убедитесь, что preflight запросы (OPTIONS) разрешены

#### 3. JWT ошибки

**Симптом:** `401 Unauthorized` или `Invalid token`

**Решение:**
- Проверьте, что токен передается в заголовке `Authorization: Bearer <token>`
- Убедитесь, что `JWT_SECRET` одинаковый при создании и проверке токена
- Проверьте срок действия токена

### Frontend проблемы

#### 1. Не загружается .env

**Симптом:** `API_URL` is null

**Решение:**
```bash
# Убедитесь, что .env добавлен в pubspec.yaml
flutter clean
flutter pub get
```

#### 2. Network ошибки на Android эмуляторе

**Симптом:** `Connection refused` при запросах к localhost

**Решение:**
- Используйте `http://10.0.2.2:8080` вместо `http://localhost:8080`
- Или запустите backend на реальном IP: `http://192.168.x.x:8080`

#### 3. SSL/Certificate ошибки

**Симптом:** `HandshakeException` или `Certificate verify failed`

**Решение (только для разработки!):**
```dart
// В api_core.dart (ТОЛЬКО ДЛЯ РАЗРАБОТКИ!)
dio.httpClientAdapter = IOHttpClientAdapter()
  ..onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  };
```

---

## Чеклист перед деплоем

### Backend
- [ ] Все тесты проходят
- [ ] `ddl-auto` установлен в `validate` (не `update`)
- [ ] JWT_SECRET изменен на production значение
- [ ] CORS настроен для production доменов
- [ ] Логирование настроено
- [ ] База данных имеет бэкапы
- [ ] SSL сертификаты установлены

### Frontend
- [ ] API_URL указывает на production backend
- [ ] Debug режим отключен
- [ ] Все sensitive данные удалены из кода
- [ ] Иконки и splash screen настроены
- [ ] Версия приложения обновлена в pubspec.yaml
- [ ] APK/AAB подписан release ключом

---

## Полезные команды

### Backend
```bash
# Просмотр логов Docker контейнера
docker logs -f bowling-backend

# Перезапуск сервиса
sudo systemctl restart bowling-backend

# Проверка портов
netstat -tulpn | grep 8080
```

### Frontend
```bash
# Очистка кэша
flutter clean

# Обновление зависимостей
flutter pub upgrade

# Анализ размера APK
flutter build apk --analyze-size

# Проверка производительности
flutter run --profile
```

### PostgreSQL
```bash
# Бэкап БД
pg_dump -U bowling_user bowling_db > backup.sql

# Восстановление БД
psql -U bowling_user bowling_db < backup.sql

# Просмотр активных подключений
SELECT * FROM pg_stat_activity WHERE datname = 'bowling_db';
```

---

## Контакты и поддержка

Для вопросов и поддержки:
- **Email:** support@bowlingmanager.com
- **GitHub Issues:** <repository-url>/issues
- **Documentation:** См. `API_DOCUMENTATION.md`

---

**Версия документа:** 1.0  
**Дата обновления:** 2025-10-08
