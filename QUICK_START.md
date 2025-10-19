# 🚀 Быстрый старт - Bowling Manager

## Первый запуск за 5 минут

### Шаг 1: Установка PostgreSQL

**Windows:**
```powershell
# Через Chocolatey
choco install postgresql

# Или скачайте с https://www.postgresql.org/download/windows/
```

**Linux:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

### Шаг 2: Создание базы данных

```bash
# Подключитесь к PostgreSQL
psql -U postgres

# Выполните команды:
CREATE DATABASE bowling_db;
CREATE USER bowling_user WITH PASSWORD 'bowling_pass';
GRANT ALL PRIVILEGES ON DATABASE bowling_db TO bowling_user;
\q
```

### Шаг 3: Настройка переменных окружения

**Корневой `.env`:**
```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/bowling_db
SPRING_DATASOURCE_USERNAME=bowling_user
SPRING_DATASOURCE_PASSWORD=bowling_pass
JWT_SECRET=your-super-secret-jwt-key-that-should-be-at-least-256-bits-long
```

**`frontend/.env`:**
```env
API_URL=http://localhost:8080
```

### Шаг 4: Запуск Backend

```bash
cd backend
./gradlew bootRun
```

Дождитесь сообщения:
```
Started BowlingAppApplication in X.XXX seconds
```

Проверьте: http://localhost:8080/swagger-ui/index.html

### Шаг 5: Запуск Frontend

**Новый терминал:**
```bash
cd frontend
flutter pub get
flutter run
```

Выберите устройство (Chrome, Android эмулятор, и т.д.)

---

## ✅ Проверка работоспособности

### 1. Тест Backend API

```bash
# Проверка health
curl http://localhost:8080/actuator/health

# Тест регистрации (замените данные)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "phone": "+79001234567",
      "password": "password123",
      "roleId": 1,
      "accountTypeId": 1
    },
    "mechanicProfile": {
      "fullName": "Иван Иванов",
      "birthDate": "1990-01-01",
      "totalExperienceYears": 10,
      "bowlingExperienceYears": 5,
      "isEntrepreneur": false
    }
  }'

# Тест авторизации
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+79001234567",
    "password": "password123"
  }'
```

### 2. Тест Frontend

1. Откройте приложение
2. Перейдите на экран регистрации
3. Заполните форму
4. Нажмите "Зарегистрироваться"
5. Войдите с созданными учетными данными

---

## 🐛 Частые проблемы

### Backend не запускается

**Ошибка:** `Connection refused` или `Authentication failed`

**Решение:**
```bash
# Проверьте статус PostgreSQL
# Windows:
pg_ctl status

# Linux:
sudo systemctl status postgresql

# macOS:
brew services list
```

### Frontend не подключается

**Для Android эмулятора:**

Измените `frontend/.env`:
```env
API_URL=http://10.0.2.2:8080
```

**Для физического устройства:**

Узнайте IP вашего компьютера:
```bash
# Windows:
ipconfig

# Linux/macOS:
ifconfig
```

Используйте:
```env
API_URL=http://192.168.X.X:8080
```

### CORS ошибки

Убедитесь, что в `backend/src/main/java/ru/bowling/config/WebConfig.java` добавлен ваш origin:

```java
.allowedOrigins(
    "http://localhost:8081",
    "http://10.0.2.2:8080",  // Для Android
    "http://192.168.X.X:8080" // Для физических устройств
)
```

---

## 📱 Запуск на разных платформах

### Web
```bash
cd frontend
flutter run -d chrome --web-port=8081
```

### Android
```bash
# Запустите эмулятор
flutter emulators --launch <emulator_id>

# Или подключите физическое устройство

# Запустите приложение
flutter run
```

### iOS (только macOS)
```bash
open -a Simulator
flutter run
```

### Desktop
```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

---

## 🎯 Следующие шаги

После успешного запуска:

1. **Изучите API:** http://localhost:8080/swagger-ui/index.html
2. **Прочитайте документацию:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
3. **Настройте production:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. **Изучите отчет:** [INTEGRATION_REPORT.md](INTEGRATION_REPORT.md)

---

## 🆘 Нужна помощь?

- **Документация:** См. файлы в корне проекта
- **Issues:** Создайте issue в репозитории
- **Email:** support@bowlingmanager.com

---

**Время первого запуска:** ~5 минут  
**Сложность:** Легко ⭐⭐☆☆☆
