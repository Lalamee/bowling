# API Documentation - Bowling Manager

## Базовая информация

**Base URL (Development):** `http://localhost:8080`  
**Base URL (Android Emulator):** `http://10.0.2.2:8080`  
**Base URL (Production):** `https://your-domain.com`

**Авторизация:** Bearer Token (JWT)  
**Content-Type:** `application/json`

---

## Оглавление

1. [Аутентификация](#аутентификация)
2. [Заявки на обслуживание](#заявки-на-обслуживание)
3. [Каталог запчастей](#каталог-запчастей)
4. [Рабочие журналы](#рабочие-журналы)
5. [История обслуживания](#история-обслуживания)
6. [Администрирование](#администрирование)
7. [Приглашения](#приглашения)
8. [Коды ошибок](#коды-ошибок)

---

## Аутентификация

### POST /api/auth/register
Регистрация нового пользователя

**Доступ:** Public

**Request Body:**
```json
{
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
  },
  "ownerProfile": null
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "status": "success"
}
```

---

### POST /api/auth/login
Авторизация пользователя

**Доступ:** Public

**Request Body:**
```json
{
  "phone": "+79001234567",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Errors:**
- `401` - Invalid phone or password
- `403` - Account is deactivated

---

### POST /api/auth/refresh
Обновление access токена

**Доступ:** Public

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### GET /api/auth/me
Получение информации о текущем пользователе

**Доступ:** Authenticated

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "id": 1,
  "phone": "+79001234567",
  "roleId": 1,
  "accountTypeId": 1,
  "isVerified": true,
  "registrationDate": "2024-01-01"
}
```

---

### POST /api/auth/logout
Выход из системы

**Доступ:** Authenticated

**Response (200):**
```json
{
  "message": "Logged out successfully",
  "status": "success"
}
```

---

### POST /api/auth/change-password
Смена пароля

**Доступ:** Authenticated

**Request Body:**
```json
{
  "oldPassword": "oldpass123",
  "newPassword": "newpass123"
}
```

**Response (200):**
```json
{
  "message": "Password changed successfully",
  "status": "success"
}
```

---

## Заявки на обслуживание

### POST /api/maintenance/requests
Создание новой заявки на обслуживание

**Доступ:** Authenticated

**Request Body:**
```json
{
  "clubId": 1,
  "laneNumber": 5,
  "mechanicId": 10,
  "managerNotes": "Срочный ремонт",
  "requestedParts": [
    {
      "catalogNumber": "ABC-123",
      "partName": "Подшипник",
      "quantity": 2
    }
  ]
}
```

**Response (201):**
```json
{
  "requestId": 100,
  "clubId": 1,
  "clubName": "Боулинг Центр",
  "laneNumber": 5,
  "mechanicId": 10,
  "mechanicName": "Иван Иванов",
  "requestDate": "2024-01-15T10:30:00",
  "status": "PENDING",
  "requestedParts": [...]
}
```

---

### GET /api/maintenance/requests
Получение всех заявок

**Доступ:** Authenticated

**Response (200):**
```json
[
  {
    "requestId": 100,
    "clubId": 1,
    "clubName": "Боулинг Центр",
    "status": "PENDING",
    ...
  }
]
```

---

### GET /api/maintenance/requests/status/{status}
Получение заявок по статусу

**Доступ:** Authenticated

**Path Parameters:**
- `status` - Статус заявки (PENDING, APPROVED, REJECTED, PUBLISHED, ASSIGNED, ORDERED, DELIVERED, ISSUED, COMPLETED, UNREPAIRABLE)

**Response (200):** Массив заявок

---

### GET /api/maintenance/requests/mechanic/{mechanicId}
Получение заявок конкретного механика

**Доступ:** Authenticated

**Path Parameters:**
- `mechanicId` - ID механика

**Response (200):** Массив заявок

---

### PUT /api/maintenance/requests/{requestId}/approve
Одобрение заявки менеджером

**Доступ:** Authenticated

**Request Body:**
```json
{
  "managerNotes": "Одобрено"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{requestId}/reject
Отклонение заявки

**Доступ:** Authenticated

**Request Body:**
```json
{
  "rejectionReason": "Недостаточно информации"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/publish
Публикация заявки для агентов

**Доступ:** Authenticated

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/assign/{agentId}
Назначение агента на заявку

**Доступ:** Authenticated

**Path Parameters:**
- `id` - ID заявки
- `agentId` - ID агента

**Response (200):** Обновленная заявка

---

### POST /api/maintenance/requests/{id}/order
Заказ запчастей

**Доступ:** Authenticated

**Request Body:**
```json
{
  "supplierId": 5,
  "orderDate": "2024-01-16T10:00:00"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/deliver
Отметка о доставке запчастей

**Доступ:** Authenticated

**Request Body:**
```json
{
  "deliveryDate": "2024-01-20T14:00:00"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/issue
Выдача запчастей механику

**Доступ:** Authenticated

**Request Body:**
```json
{
  "issueDate": "2024-01-21T09:00:00"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/close
Закрытие заявки

**Доступ:** Authenticated

**Request Body (optional):**
```json
{
  "completionNotes": "Работа выполнена"
}
```

**Response (200):** Обновленная заявка

---

### PUT /api/maintenance/requests/{id}/unrepairable
Отметка оборудования как неремонтопригодного

**Доступ:** Authenticated

**Request Body:**
```json
{
  "rejectionReason": "Оборудование не подлежит ремонту"
}
```

**Response (200):** Обновленная заявка

---

## Каталог запчастей

### POST /api/parts/search
Поиск запчастей с фильтрацией

**Доступ:** Authenticated

**Request Body:**
```json
{
  "searchQuery": "подшипник",
  "manufacturerId": 5,
  "catalogNumber": "ABC",
  "isUnique": true,
  "equipmentType": "PINSETTER",
  "page": 0,
  "size": 20,
  "sortBy": "catalogId",
  "sortDirection": "ASC"
}
```

**Response (200):**
```json
[
  {
    "catalogId": 1,
    "manufacturerId": 5,
    "manufacturerName": "Brunswick",
    "catalogNumber": "ABC-123",
    "officialNameEn": "Bearing",
    "officialNameRu": "Подшипник",
    "commonName": "Подшипник основной",
    "description": "Описание",
    "normalServiceLife": 12,
    "unit": "шт",
    "isUnique": false,
    "availableQuantity": 10,
    "availabilityStatus": "IN_STOCK"
  }
]
```

---

### GET /api/parts/catalog/{catalogNumber}
Получение запчасти по каталожному номеру

**Доступ:** Authenticated

**Response (200):** Объект запчасти  
**Response (404):** Запчасть не найдена

---

### GET /api/parts/unique
Получение уникальных запчастей

**Доступ:** Authenticated

**Response (200):** Массив уникальных запчастей

---

### GET /api/parts/all
Получение всех запчастей

**Доступ:** Authenticated

**Response (200):** Массив всех запчастей

---

## Рабочие журналы

### POST /api/worklogs
Создание записи в рабочем журнале

**Доступ:** ADMIN, OWNER, MECHANIC

**Request Body:**
```json
{
  "clubId": 1,
  "laneNumber": 5,
  "mechanicId": 10,
  "status": "IN_PROGRESS",
  "workType": "REPAIR",
  "problemDescription": "Описание проблемы",
  "estimatedHours": 2.5,
  "priority": 3
}
```

**Response (200):** Созданная запись

---

### GET /api/worklogs/{id}
Получение записи журнала по ID

**Доступ:** ADMIN, OWNER, MECHANIC

**Response (200):** Запись журнала

---

### PUT /api/worklogs/{id}
Обновление записи журнала

**Доступ:** ADMIN, OWNER, MECHANIC

**Request Body:** Обновленные данные

**Response (200):** Обновленная запись

---

### DELETE /api/worklogs/{id}
Удаление записи журнала

**Доступ:** ADMIN, OWNER

**Response (204):** No Content

---

### POST /api/worklogs/search
Поиск записей журнала

**Доступ:** ADMIN, OWNER, MECHANIC

**Request Body:**
```json
{
  "clubId": 1,
  "mechanicId": 10,
  "status": "COMPLETED",
  "workType": "REPAIR",
  "startDate": "2024-01-01",
  "endDate": "2024-01-31",
  "page": 0,
  "size": 20
}
```

**Response (200):**
```json
{
  "content": [...],
  "totalElements": 100,
  "totalPages": 5,
  "size": 20,
  "number": 0
}
```

---

## История обслуживания

### POST /api/service-history
Создание записи истории обслуживания

**Доступ:** ADMIN, OWNER

**Request Body:**
```json
{
  "clubId": 1,
  "laneNumber": 5,
  "serviceDate": "2024-01-15T10:00:00",
  "serviceType": "PREVENTIVE",
  "description": "Плановое обслуживание",
  "laborHours": 3.5,
  "totalCost": 5000.0
}
```

**Response (200):** Созданная запись

---

### GET /api/service-history/{id}
Получение записи истории по ID

**Доступ:** ADMIN, OWNER, MECHANIC

**Response (200):** Запись истории

---

### GET /api/service-history/club/{clubId}
Получение истории обслуживания клуба

**Доступ:** ADMIN, OWNER

**Response (200):** Массив записей истории

---

## Администрирование

### PUT /api/admin/users/{userId}/verify
Верификация пользователя

**Доступ:** ADMIN

**Response (200):** OK

---

### PUT /api/admin/users/{userId}/activate
Активация пользователя

**Доступ:** ADMIN

**Response (200):** OK

---

### PUT /api/admin/users/{userId}/deactivate
Деактивация пользователя

**Доступ:** ADMIN

**Response (200):** OK

---

### DELETE /api/admin/users/{userId}/reject
Отклонение регистрации пользователя

**Доступ:** ADMIN

**Response (200):** OK

---

## Приглашения

### POST /api/invitations/club/{clubId}/mechanic/{mechanicId}
Приглашение механика в клуб

**Доступ:** OWNER

**Response (200):** OK

---

### PUT /api/invitations/{invitationId}/accept
Принятие приглашения

**Доступ:** MECHANIC

**Response (200):** OK

---

### PUT /api/invitations/{invitationId}/reject
Отклонение приглашения

**Доступ:** MECHANIC

**Response (200):** OK

---

## Коды ошибок

| Код | Описание |
|-----|----------|
| 200 | OK - Успешный запрос |
| 201 | Created - Ресурс создан |
| 204 | No Content - Успешно, без содержимого |
| 400 | Bad Request - Неверный запрос |
| 401 | Unauthorized - Не авторизован |
| 403 | Forbidden - Доступ запрещен |
| 404 | Not Found - Ресурс не найден |
| 500 | Internal Server Error - Внутренняя ошибка сервера |

---

## Примеры использования (Flutter)

### Авторизация
```dart
import 'package:flutter_application_1/api/api_service.dart';
import 'package:flutter_application_1/models/user_login_dto.dart';

final apiService = ApiService();

try {
  final loginDto = UserLoginDto(
    phone: '+79001234567',
    password: 'password123',
  );
  
  final response = await apiService.login(loginDto);
  await apiService.saveTokens(response);
  
  print('Успешная авторизация!');
} catch (e) {
  print('Ошибка: $e');
}
```

### Создание заявки
```dart
final request = PartRequestDto(
  clubId: 1,
  laneNumber: 5,
  mechanicId: 10,
  requestedParts: [
    RequestedPartDto(
      catalogNumber: 'ABC-123',
      partName: 'Подшипник',
      quantity: 2,
    ),
  ],
);

final result = await apiService.createMaintenanceRequest(request);
print('Заявка создана: ${result.requestId}');
```

### Поиск запчастей
```dart
final searchDto = PartsSearchDto(
  searchQuery: 'подшипник',
  page: 0,
  size: 20,
);

final parts = await apiService.searchParts(searchDto);
print('Найдено запчастей: ${parts.length}');
```

---

## Переменные окружения

### Backend (.env)
```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/bowling_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=password
JWT_SECRET=your-super-secret-jwt-key-256-bits
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000
CORS_ALLOWED_ORIGINS=http://localhost:8081,http://10.0.2.2:8080
```

### Frontend (.env)
```env
API_URL=http://localhost:8080
# Для Android эмулятора:
# API_URL=http://10.0.2.2:8080
```

---

## Swagger UI

После запуска backend, Swagger UI доступен по адресу:
```
http://localhost:8080/swagger-ui/index.html
```

OpenAPI спецификация:
```
http://localhost:8080/v3/api-docs
```
