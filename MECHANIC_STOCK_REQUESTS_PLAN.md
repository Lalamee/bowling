# План стыковки бэка и фронта для "Запросов механика на выдачу запчастей"

## Текущее состояние
- **Backend**
  - Запросы механику описаны сущностью `MaintenanceRequest` и связываются с позициями `RequestPart` без явного поля типа заявки: сейчас статусы ограничены `NEW/APPROVED/IN_PROGRESS/DONE/CLOSED/UNREPAIRABLE`. Это не покрывает цепочку "отправлен менеджеру → согласование → частичное одобрение/отклонение". ❗️Нужно добавить TODO для выделения типа заявки (например, ISSUE_FROM_STOCK) и уточнения статусов выдачи со склада. См. `MaintenanceRequest` и `MaintenanceRequestStatus` в `backend/src/main/java/ru/bowling/bowlingapp/Entity/MaintenanceRequest.java` и `.../MaintenanceRequestStatus.java`.
  - Позиции заявки (`RequestPart`) уже хранят остаточную информацию (количество, наличие, дата выдачи/доставки, принятие и комментарии), но в `PartStatus` нет этапов частичного одобрения/отклонения выдачи. Требуется TODO для уточнения статусов на уровне позиций. См. `backend/src/main/java/ru/bowling/bowlingapp/Entity/RequestPart.java` и `.../Entity/enums/PartStatus.java`.
  - DTO ответа `MaintenanceRequestResponseDTO` прокидывает позиции без полей для выданного количества и комментария менеджера по позиции. Данные есть на сущности (`acceptedQuantity`, `acceptanceComment`), но не используются на фронте для экрана менеджера.
  - Сервис `MaintenanceRequestService` создаёт и утверждает заявки, но нет явной логики частичного одобрения/выдачи со склада и проверки остатков; отсутствует отдельный эндпоинт для частичного согласования.
- **Frontend**
  - Экран создания заявки (`CreateMaintenanceRequestScreen`) уже поддерживает выбор клуба/дорожки, поиск деталей и минимальную валидацию количества > 0, но нет явных подсказок, что это запрос на выдачу со склада.
  - Модель `MaintenanceRequestResponseDto` отображает статус и позиции, но не показывает выданное количество и комментарий менеджера по каждой позиции, поэтому менеджеру/механику сложно увидеть частичное одобрение.
  - Список заявок (`MaintenanceRequestsScreen`) уже покрывает состояния загрузки/ошибки/пусто, но фильтры статусов опираются на текущий набор статусов без этапов согласования выдачи.

## Что обновить (по файлам/сущностям)
- `backend/src/main/java/ru/bowling/bowlingapp/Entity/MaintenanceRequest.java` и `.../Entity/enums/MaintenanceRequestStatus.java`
  - Добавить TODO-поле типа заявки (например, `requestType`) и TODO-статусы для этапов выдачи со склада (отправлен менеджеру/на согласовании/частично одобрен/отклонён).
- `backend/src/main/java/ru/bowling/bowlingapp/Entity/RequestPart.java` и `.../Entity/enums/PartStatus.java`
  - Добавить TODO-статусы для позиций: "ожидает согласования", "одобрено к выдаче", "частично одобрено", "отклонено менеджером"; предусмотреть хранение `approvedQuantity` (можно переиспользовать `acceptedQuantity`).
- `backend/src/main/java/ru/bowling/bowlingapp/DTO/MaintenanceRequestResponseDTO.java`
  - Прокинуть в DTO `acceptedQuantity`/`acceptanceComment` как результат решения менеджера по выдаче.
- `backend/src/main/java/ru/bowling/bowlingapp/Service/MaintenanceRequestService.java`
  - Добавить TODO-метод/контракт для частичного одобрения позиций (ID заявки + список `{partId, requestedQty, approvedQty, comment}`), который обновляет статусы позиций и остатки склада.
- `frontend/lib/models/maintenance_request_response_dto.dart`
  - Отобразить на UI поля `acceptedQuantity`/`acceptanceComment` и (при наличии) статус позиции, чтобы показать механику итог решения менеджера.
- `frontend/lib/features/orders/presentation/screens/maintenance_requests_screen.dart`
  - Расширить фильтры статусов под новые этапы выдачи (после добавления на бэке), показать пустой стейт "у вас пока нет запросов на выдачу" отдельно от других заявок.
- `frontend/lib/features/orders/presentation/screens/create_maintenance_request_screen.dart`
  - Добавить пометку/подсказку, что создаваемая заявка — на выдачу со склада; оставить TODO для выбора типа заявки, если бэк добавит поле.
- `frontend/lib/core/repositories/maintenance_repository.dart` и `frontend/lib/api/api_service.dart`
  - После появления эндпоинта частичного одобрения добавить метод репозитория + вызов API. Пока оставить TODO-контракт.

## Предлагаемые фрагменты изменений
### Тип и статусы заявки на бэке
```java
// TODO: requestType (ISSUE_FROM_STOCK) to differentiate issuance vs supply
// @Enumerated(EnumType.STRING)
// private MaintenanceRequestType requestType;

// TODO: extend statuses for issuance workflow
// SENT_TO_MANAGER, UNDER_REVIEW, PARTIALLY_APPROVED, ISSUED, REJECTED
```

### Статусы и количества по позициям
```java
public enum PartStatus {
    ORDERED,
    DELIVERED,
    INSTALLED,
    ACCEPTED,
    PARTIALLY_ACCEPTED,
    REJECTED,
    // TODO: APPROVED_FOR_ISSUE, ISSUE_REJECTED, PARTIALLY_ISSUED
}

// In RequestPart
// private Integer approvedQuantity; // TODO: reuse acceptedQuantity or add explicit field
// private String managerDecisionComment; // TODO for per-position rejection reason
```

### DTO для решения менеджера по позициям
```java
// backend/src/main/java/ru/bowling/bowlingapp/DTO/MaintenanceRequestResponseDTO.java
@Builder
public static class RequestPartResponseDTO {
    private Integer acceptedQuantity; // already exists, expose to frontend
    private String acceptanceComment; // already exists
    // TODO: approvedStatus to reflect manager decision per position
}
```

### Контракт частичного одобрения/выдачи
```java
// TODO in MaintenanceRequestService
public MaintenanceRequestResponseDTO approveFromStock(
        Long requestId,
        List<PartApprovalDTO> approvals) {
    // approvals: [{partId, requestedQty, approvedQty, comment}]
    // 1) validate requestedQty > 0, approvedQty >=0 && <= available
    // 2) update RequestPart.acceptedQuantity/acceptanceComment/status
    // 3) decrement WarehouseInventory by approvedQty
    // 4) update request status (PARTIALLY_APPROVED or DONE when all issued)
}
```

### Обновление фронтенд-модели
```dart
class RequestPartResponseDto {
  final int? acceptedQuantity; // already parsed
  final String? acceptanceComment; // already parsed
  // TODO: approvedStatus for manager decision per position
}
```

### UI подсказка при создании заявки
```dart
// create_maintenance_request_screen.dart
Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  child: Text(
    'Запрос используется для выдачи запчастей со склада клуба. ',
    style: TextStyle(color: AppColors.darkGray),
  ),
),
// TODO: Dropdown for request type when backend adds requestType
```

### Фильтрация и пустой стейт списков
```dart
// maintenance_requests_screen.dart
if (requests.isEmpty) {
  return Center(
    child: Text('У вас пока нет запросов на выдачу'),
  );
}
// TODO: extend _statusFilters when backend exposes UNDER_REVIEW / PARTIALLY_APPROVED
```
