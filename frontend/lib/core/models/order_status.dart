import 'dart:collection';

/// Категории статусов заявок, используемые для фильтров и бейджей.
enum OrderStatusCategory { pending, confirmed, archived }

/// Фиксированный перечень пользовательских статусов, отображаемых в приложении.
///
/// Каждый статус объединяет несколько бэкенд-значений и отображается как одна
/// из трёх вкладок: «На проверке», «Подтверждённый», «Архив».
enum OrderStatusType {
  pending('На проверке', {
    'NEW',
    'PENDING',
    'WAITING',
    'REQUESTED',
    'DRAFT',
  }, OrderStatusCategory.pending),
  confirmed('Подтверждённый', {
    'APPROVED',
    'CONFIRMED',
    'IN_PROGRESS',
    'ACCEPTED',
  }, OrderStatusCategory.confirmed),
  archived('Архив', {
    'DONE',
    'COMPLETED',
    'CLOSED',
    'UNREPAIRABLE',
    'REJECTED',
    'ARCHIVED',
    'CANCELLED',
  }, OrderStatusCategory.archived);

  const OrderStatusType(this.label, Set<String> backendKeys, this.category)
      : backendKeys = UnmodifiableSetView(backendKeys);

  /// Отображаемое название вкладки/чипа.
  final String label;

  /// Перечень исходных статусов, попадающих в данную вкладку.
  final Set<String> backendKeys;

  /// Агрегированная категория (совпадает с самим перечислением).
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

  /// Возвращает тип статуса по исходному ключу бэкенда.
  static OrderStatusType? fromRaw(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _index[normalized];
  }

  /// Проверяет, принадлежит ли исходное значение данной вкладке.
  bool matches(String? raw) => fromRaw(raw) == this;
}

/// Фиксированный порядок отображения фильтров статусов.
const List<OrderStatusType> kOrderStatusFilterOrder = [
  OrderStatusType.pending,
  OrderStatusType.confirmed,
  OrderStatusType.archived,
];

/// Возвращает категорию агрегированного статуса по исходному значению.
OrderStatusCategory mapOrderStatusCategory(String? rawStatus) {
  final resolved = OrderStatusType.fromRaw(rawStatus);
  return resolved?.category ?? OrderStatusCategory.pending;
}

/// Человекочитаемое название категории.
String orderStatusCategoryLabel(OrderStatusCategory category) {
  switch (category) {
    case OrderStatusCategory.archived:
      return 'Архив';
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

/// Возвращает пользовательское название статуса по исходному значению.
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
