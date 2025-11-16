# Проверка прав доступа (премиум/база) и push-уведомлений

## Текущее состояние

### Бэкенд
- `User` уже содержит ссылку на `AccountType`, но сам тип хранит только `name` без признаков премиум/базового статуса. В DTO `UserInfoDTO` нет поля статуса аккаунта. Это не позволяет проверять премиум-права на уровне сервисов/контроллеров. 【F:backend/src/main/java/ru/bowling/bowlingapp/Entity/User.java†L23-L47】【F:backend/src/main/java/ru/bowling/bowlingapp/Entity/AccountType.java†L9-L21】【F:backend/src/main/java/ru/bowling/bowlingapp/DTO/UserInfoDTO.java†L13-L19】
- Сервис уведомлений (`NotificationService`) сейчас только логирует события без реальной доставки (WebSocket/push). Поддерживаются вызовы при создании заявок и обновлениях work log, но нет адаптеров под клиентские каналы. 【F:backend/src/main/java/ru/bowling/bowlingapp/Service/NotificationService.java†L15-L118】

### Фронтенд (Flutter)
- Профили и ACL опираются на `accountTypeId/accountTypeName`, но премиум/база не различаются; нет условного рендера для ограничений (например, доступа к базе знаний или расширенным функциям склада). 【F:frontend/lib/models/user_info_dto.dart†L5-L33】【F:frontend/lib/core/services/authz/acl.dart†L8-L83】
- Экран уведомлений (`NotificationsPage`) и бэйдж (`NotificationsBadgeController`) работают через периодический опрос заявок, нет подписки на WebSocket/Push и нормализации типов событий. 【F:frontend/lib/features/orders/notifications/notifications_badge_controller.dart†L8-L98】【F:frontend/lib/features/orders/notifications/notifications_page.dart†L21-L110】

## Что нужно доработать

### Роли/статусы аккаунтов (премиум/база)
- **Бэкенд**: добавить признак премиум-статуса в `AccountType` (например, `isPremium` или перечисление `status`) и вернуть его в `UserInfoDTO`. До появления миграций пометить поля TODO в моделях и DTO. Добавить проверки прав в сервисах, где выдаётся расширенный доступ (база знаний, склад, БД специалистов). TODO: конкретные эндпоинты, если в ТЗ указаны ограничения.
- **Фронтенд**: сохранять статус аккаунта в `UserInfoDto` и `LocalAuthStorage`, использовать его в ACL/гвардах экранов. В экранах с расширенным доступом (база знаний, склад, специалисты) спрятать кнопки/действия для базового тарифа и выводить сообщение «функция доступна только премиум-аккаунтам». TODO: список экранов с премиум-функциями после уточнения ТЗ.
- **Управление статусами**: для администраторов — экран/действия смены статуса и просмотра заявок на премиум. Для менеджеров — инициирование смены статуса механиков (перевод в свободные агенты) с проверкой ролей. TODO: если на бэкенде нет эндпоинтов — описать API-запросы и добавить проверки доступа.

### Push/WebSocket уведомления
- **Бэкенд**: расширить `NotificationService` адаптером на существующий стек (например, STOMP/WebSocket через Spring). Добавить нормализованный payload: `type`, `entityId`, `message`, `createdAt`, `meta`. События минимум: смена статуса заявок (регистрация, расширенные права, поставка/выдача запчастей), сроки ТО/износа, подтверждения менеджером заявок, фиксация сроков выполнения заказа, невозможность ремонта, претензии. Если истории уведомлений нет — TODO эндпоинт `GET /api/notifications/history` с пагинацией и фильтром по роли.
- **Фронтенд**: создать слой подписки на WebSocket (использовать уже выбранный в проекте клиент, без новых зависимостей). Нормализовать входящие события в модель `AppNotification` (type, text, createdAt, link). Показать бэйдж новых уведомлений в профилях менеджера/владельца и общий список уведомлений с переходами на соответствующие экраны (заявка, дорожка, претензия). При отсутствии прав на переход — отображать ошибку и/или диалог. Добавить стратегию переподключения и обработку оффлайна (локальный буфер до повторного коннекта). TODO: если сервер не присылает историю — показывать текст «уведомлений пока нет» и отметить необходимость REST-истории.

## Предлагаемые фрагменты изменений

### DTO/модели (бэкенд)
```java
// TODO: добавить после согласования схемы
@Entity
@Table(name = "account_type")
public class AccountType {
    // ...
    // @Column(name = "is_premium", nullable = false)
    // private Boolean isPremium;
}

public class UserInfoDTO {
    private Long accountTypeId;
    private Boolean isPremium; // TODO: заполнить из AccountType
}
```

### Проверки на сервисах (пример)
```java
// TODO: добавить проверку в сервисе работы с базой знаний
if (user.getAccountType() == null || Boolean.FALSE.equals(user.getAccountType().getIsPremium())) {
    throw new AccessDeniedException("Доступ к расширенной базе знаний только для премиум-аккаунтов");
}
```

### Клиент: хранение статуса и защита UI
```dart
// UserInfoDto
class UserInfoDto {
  final bool? isPremium; // TODO: заполнить с бэка
  // ...
  factory UserInfoDto.fromJson(Map<String, dynamic> json) => UserInfoDto(
        // ...
        isPremium: json['isPremium'] as bool?,
      );
}

// Пример условного рендера в KnowledgeBaseScreen
if (!(me.isPremium ?? false)) {
  return const PremiumRequiredBanner(message: 'Функция доступна только премиум-аккаунтам');
}
```

### Клиент: единый обработчик уведомлений
```dart
// TODO: использовать существующий WebSocket клиент проекта
final _ws = AppWebSocket(channel: '/user/notifications');
final _controller = StreamController<AppNotification>();

_ws.onMessage((data) {
  final event = AppNotification.fromJson(data);
  _controller.add(event);
});

// В NotificationsBadgeController
_ws.connectWithRetry();
_controller.stream.listen((event) {
  _pending.add(event);
  notifyListeners();
});
```

### Навигация из уведомлений
```dart
void onNotificationTap(AppNotification notification) {
  switch (notification.type) {
    case NotificationType.requestStatus:
      Navigator.pushNamed(context, Routes.requestDetails, arguments: notification.entityId);
      break;
    // TODO: остальные типы (ТО, претензии, склад)
    default:
      // показать тост/диалог
  }
}
```

### TODO для отсутствующих частей
- Бэкенд: схема хранения истории уведомлений и признак прочитанных; эндпоинты для запросов/решений по премиум-аккаунтам.
- Фронтенд: экраны администратора для утверждения премиум-заявок и просмотра истории изменений прав; обработка ошибок при отсутствии доступа к объекту по ссылке из уведомления.
