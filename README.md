# Bowling Manager — Integrated Full Stack Application

Система управления боулинг-клубами с мобильным приложением на Flutter и backend на Spring Boot.

## 📚 Документация

- **[API Documentation](API_DOCUMENTATION.md)** - Полное описание всех API эндпоинтов
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Руководство по развертыванию
- **[Integration Report](INTEGRATION_REPORT.md)** - Отчет по интеграции backend и frontend

## 🚀 Быстрый старт

### Требования

- **Backend:** Java 17+, PostgreSQL 14+, Gradle 8+
- **Frontend:** Flutter 3.0+, Dart 3.0+

### 1. Настройка базы данных

```bash
# Создание БД
psql -U postgres
CREATE DATABASE bowling_db;
CREATE USER bowling_user WITH PASSWORD 'bowling_pass';
GRANT ALL PRIVILEGES ON DATABASE bowling_db TO bowling_user;
\q
```

### 2. Настройка переменных окружения

Создайте `.env` в корне проекта:

```env
# Backend
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/bowling_db
SPRING_DATASOURCE_USERNAME=bowling_user
SPRING_DATASOURCE_PASSWORD=bowling_pass
JWT_SECRET=your-super-secret-jwt-key-256-bits

# Frontend
API_URL=http://localhost:8080
```

Создайте `frontend/.env`:

```env
API_URL=http://localhost:8080
```

### 3. Запуск Backend

```bash
cd backend
JAVA_HOME=$HOME/.local/share/mise/installs/java/17.0.2 ./gradlew :auth-service:bootRun :core-service:bootRun
```

Auth service: `http://localhost:8082`  
Core service: `http://localhost:8081`  
Swagger UI (core): `http://localhost:8081/swagger-ui/index.html`

### 4. Запуск Frontend

```bash
cd frontend
flutter pub get
flutter run

# Для web:
# flutter run -d chrome --web-port=8081

# Для Android эмулятора (измените API_URL на http://10.0.2.2:8080)
```

## 🏗️ Архитектура

### Backend (Spring Boot microservices)
- **Контроллеры:** 8 (Auth, Maintenance, Parts, WorkLog, ServiceHistory, Admin, Invitations, Inventory)
- **Сервисы:** 11
- **Репозитории:** 20
- **Entities:** 42
- **DTO:** 30
- **Авторизация:** JWT (Access + Refresh tokens)
- **База данных:** PostgreSQL
- **API документация:** Swagger/OpenAPI

### Frontend (Flutter)
- **Архитектура:** Feature-first
- **Сетевой слой:** Dio + Interceptors
- **Хранилище:** FlutterSecureStorage (токены)
- **Модели:** 24 DTO с fromJson/toJson
- **API сервис:** Типизированный ApiService

## 📦 Основные возможности

### Для механиков
- ✅ Создание заявок на обслуживание
- ✅ Поиск запчастей в каталоге
- ✅ Ведение рабочих журналов
- ✅ Просмотр истории обслуживания

### Для владельцев клубов
- ✅ Управление заявками (одобрение/отклонение)
- ✅ Приглашение механиков
- ✅ Просмотр отчетов и статистики
- ✅ Управление оборудованием

### Для администраторов
- ✅ Верификация пользователей
- ✅ Управление доступом
- ✅ Модерация заявок

## 🔐 Безопасность

- JWT авторизация с автоматическим обновлением токенов
- Хеширование паролей (BCrypt)
- CORS защита
- Secure storage на клиенте
- Role-based access control

## 🛠️ Технологии

**Backend:**
- Spring Boot 3.5.3 (auth-service + core-service)
- Spring Security + JWT
- Spring Data JPA
- PostgreSQL
- MapStruct
- Lombok
- Springdoc OpenAPI

**Frontend:**
- Flutter 3.0+
- Dio (HTTP client)
- flutter_secure_storage
- flutter_dotenv

## 📊 API Endpoints

Всего: **50+ эндпоинтов**

- **Auth:** 7 эндпоинтов (регистрация, вход, обновление токена, и т.д.)
- **Maintenance:** 11 эндпоинтов (создание, одобрение, статусы, и т.д.)
- **Parts:** 5 эндпоинтов (поиск, каталог, уникальные)
- **WorkLogs:** 5 эндпоинтов (CRUD + поиск)
- **ServiceHistory:** 3 эндпоинта
- **Admin:** 4 эндпоинта
- **Invitations:** 3 эндпоинта
- **Inventory:** 4 эндпоинта

Подробнее см. [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 🧪 Тестирование

```bash
# Backend тесты
cd backend
./gradlew test

# Frontend тесты
cd frontend
flutter test
```

## 📱 Сборка для production

### Android APK
```bash
cd frontend
flutter build apk --release
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS (требуется macOS)
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🐳 Docker

```bash
cd backend
docker compose up -d auth-service core-service
```

## 📝 Структура проекта

```
bowling/
├── backend/                 # Spring Boot приложение
│   ├── src/main/java/
│   │   └── ru/bowling/bowlingapp/
│   │       ├── Controller/
│   │       ├── Service/
│   │       ├── Repository/
│   │       ├── Entity/
│   │       ├── DTO/
│   │       ├── Config/
│   │       └── Security/
│   └── src/main/resources/
│       └── application.yml
├── frontend/                # Flutter приложение
│   ├── lib/
│   │   ├── api/            # API слой
│   │   ├── models/         # DTO модели
│   │   ├── features/       # Модули приложения
│   │   ├── core/           # Роутинг, темы
│   │   └── shared/         # Общие компоненты
│   └── pubspec.yaml
├── API_DOCUMENTATION.md     # API документация
├── DEPLOYMENT_GUIDE.md      # Гайд по развертыванию
├── INTEGRATION_REPORT.md    # Отчет по интеграции
└── README.md               # Этот файл
```

## 🔧 Troubleshooting

### Backend не запускается
- Проверьте, что PostgreSQL запущен
- Проверьте настройки подключения в `.env`
- Убедитесь, что порт 8080 свободен

### Frontend не подключается к backend
- Для Android эмулятора используйте `http://10.0.2.2:8080`
- Проверьте, что backend запущен
- Проверьте CORS настройки

### Ошибки авторизации
- Убедитесь, что JWT_SECRET одинаковый
- Проверьте срок действия токенов
- Очистите токены в secure storage

Подробнее см. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting)

## 📞 Поддержка

- **Issues:** Создайте issue в репозитории
- **Email:** support@bowlingmanager.com
- **Документация:** См. файлы документации в корне проекта

## 📄 Лицензия

[Укажите вашу лицензию]

---

**Статус:** ✅ Готово к развертыванию  
**Версия:** 1.0.0  
**Дата:** 2025-10-08
