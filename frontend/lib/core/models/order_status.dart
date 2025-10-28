import 'dart:collection';

/// Категории статусов заявок, используемые для группировки и бейджей.
enum OrderStatusCategory { pending, confirmed, archived }

/// Единый перечислимый набор статусов заявок.
///
/// Каждый статус хранит читаемое название, набор исходных ключей,
/// а также категорию для отображения агрегированных состояний.
enum OrderStatusType {
  draft('Черновик', {'DRAFT'}, OrderStatusCategory.pending),
  newRequest('Новая', {'NEW'}, OrderStatusCategory.pending),
  pending('В ожидании', {'PENDING'}, OrderStatusCategory.pending),
  approved('Одобрена', {'APPROVED'}, OrderStatusCategory.confirmed),
  confirmed('Подтверждён', {'CONFIRMED'}, OrderStatusCategory.confirmed),
  inProgress('В работе', {'IN_PROGRESS'}, OrderStatusCategory.confirmed),
  completed('Завершена', {'COMPLETED', 'DONE'}, OrderStatusCategory.archived),
  closed('Закрыта', {'CLOSED'}, OrderStatusCategory.archived),
  unrepairable('Не ремонтопригодно', {'UNREPAIRABLE'}, OrderStatusCategory.archived),
  rejected('Отклонена', {'REJECTED'}, OrderStatusCategory.archived),
  archived('Архив', {'ARCHIVED'}, OrderStatusCategory.archived);

  const OrderStatusType(this.label, this.backendKeys, this.category);

  /// Человекочитаемое название статуса.
  final String label;

  /// Набор исходных ключей статуса из backend.
  final Set<String> backendKeys;

  /// Группа статусов для агрегированных фильтров и бейджей.
  final OrderStatusCategory category;

  static final Map<String, OrderStatusType> _index = _buildIndex();

  static Map<String, OrderStatusType> _buildIndex() {
    final map = <String, OrderStatusType>{};
    for (final status in OrderStatusType.values) {
      for (final key in status.backendKeys) {
        map[key] = status;
      }
    }
    return UnmodifiableMapView(map);
  }

  /// Возвращает статус по исходному ключу, если он известен приложению.
  static OrderStatusType? fromRaw(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _index[normalized];
  }

  /// Проверяет, относится ли исходное значение к данному статусу.
  bool matches(String? raw) => fromRaw(raw) == this;
}

/// Фиксированный список статусов для фильтрации и отображения чипов.
const List<OrderStatusType> kOrderStatusFilterOrder = [
  OrderStatusType.draft,
  OrderStatusType.newRequest,
  OrderStatusType.pending,
  OrderStatusType.approved,
  OrderStatusType.confirmed,
  OrderStatusType.inProgress,
  OrderStatusType.completed,
  OrderStatusType.closed,
  OrderStatusType.unrepairable,
  OrderStatusType.rejected,
  OrderStatusType.archived,
];

/// Возвращает категорию агрегированного статуса по исходному значению.
OrderStatusCategory mapOrderStatusCategory(String? rawStatus) {
  final resolved = OrderStatusType.fromRaw(rawStatus);
  return resolved?.category ?? OrderStatusCategory.pending;
}

/// Человекочитаемое название категории статуса.
String orderStatusCategoryLabel(OrderStatusCategory category) {
  switch (category) {
    case OrderStatusCategory.archived:
      return 'Архивный';
    case OrderStatusCategory.confirmed:
      return 'Подтверждённый';
    case OrderStatusCategory.pending:
    default:
      return 'На проверке';
  }
}

/// Возвращает, относится ли исходный статус к архивным.
bool isArchivedStatus(String? rawStatus) =>
    mapOrderStatusCategory(rawStatus) == OrderStatusCategory.archived;

/// Возвращает, относится ли исходный статус к подтверждённым.
bool isConfirmedStatus(String? rawStatus) =>
    mapOrderStatusCategory(rawStatus) == OrderStatusCategory.confirmed;

/// Возвращает, относится ли исходный статус к ожидающим подтверждения.
bool isPendingStatus(String? rawStatus) =>
    mapOrderStatusCategory(rawStatus) == OrderStatusCategory.pending;

/// Человекочитаемое название статуса по исходному значению.
String describeOrderStatus(String? rawStatus) {
  final resolved = OrderStatusType.fromRaw(rawStatus);
  if (resolved != null) {
    return resolved.label;
  }
  final fallback = rawStatus?.trim();
  if (fallback == null || fallback.isEmpty) {
    return 'Неизвестно';
  }
  return fallback;
}
