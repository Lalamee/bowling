# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Notifications & ACL (frontend-only)
- Менеджеры и владельцы видят новый экран «Оповещения», доступный из профиля. Число непрочитанных заявок отображается бейджем на плитке и обновляется каждые 30 секунд без перезагрузки приложения.
- Маркер «прочитано» хранится локально в `SharedPreferences` (ключ `notifications.lastSeen.<user>`), поэтому отметка действует только на текущем устройстве.
- Контроллер `NotificationsBadgeController` фильтрует заявки по доступным клубам и обновляет счётчик при вызове `markAllAsRead()`.
- Для отладки можно сбросить состояние, вызвав `LastSeenStorage.clear(...)` из DevTools/консоли и повторно открыть экран — все заявки снова будут считаться новыми.
- Проверка доступа реализована через `UserAccessScope` (`core/services/authz/acl.dart`) и применяется на всех экранах истории и карточках заявок; при попытке открыть чужую заявку отображается экран с запретом доступа.

## Order history & search fixes
- Фронтенд использует единый справочник статусов `core/models/order_status.dart`. Фильтры и чипы в истории заказов отображают фиксированный порядок значений без дублей, а неизвестные статусы выводятся как текст без отдельного чипа.
- Экран «История» и «Архив» переключаются локально без отдельной навигации: `Navigator.maybePop` возвращает обратно, поэтому пользователь не застрянет на архиве.
- Глобальный поиск (`features/search/presentation/screens/global_search_screen.dart`) выполняется локально и агрегирует результаты по четырём категориям: заявки, клубы, склад, профиль. Тап по карточке открывает соответствующий экран через существующие маршруты.
- Для поиска по складу используется кэш позиций из доступных клубов (`LocalSearchService.searchInventory`); админ видит все клубы, менеджеры/владельцы/механики — только свои.
