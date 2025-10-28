import 'dart:collection';

/// Категории статусов заявок, используемые для фильтров и бейджей.
enum OrderStatusCategory { pending, confirmed, archived }

/// Фиксированный перечень пользовательских статусов, отображаемых в приложении.
///
/// Каждый статус объединяет несколько бэкенд-значений и отображается как одна
/// из трёх вкладок: «На проверке», «Подтверждённый», «Архив».
enum OrderStatusType {
  pending,
  confirmed,
  archived;

  /// Возвращает тип статуса по исходному ключу бэкенда.
  static OrderStatusType? fromRaw(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _index[normalized];
  }
}

const Set<String> _pendingBackendKeys = <String>{
  'NEW',
  'PENDING',
  'WAITING',
  'REQUESTED',
  'DRAFT',
};

const Set<String> _confirmedBackendKeys = <String>{
  'APPROVED',
  'CONFIRMED',
  'IN_PROGRESS',
  'ACCEPTED',
};

const Set<String> _archivedBackendKeys = <String>{
  'DONE',
  'COMPLETED',
  'CLOSED',
  'UNREPAIRABLE',
  'REJECTED',
  'ARCHIVED',
  'CANCELLED',
};

final Map<OrderStatusType, UnmodifiableSetView<String>> _backendKeysByType =
    <OrderStatusType, UnmodifiableSetView<String>>{
  OrderStatusType.pending:
      UnmodifiableSetView<String>(_pendingBackendKeys),
  OrderStatusType.confirmed:
      UnmodifiableSetView<String>(_confirmedBackendKeys),
  OrderStatusType.archived:
      UnmodifiableSetView<String>(_archivedBackendKeys),
};

final UnmodifiableSetView<String> _emptyStatusSet =
    UnmodifiableSetView<String>(const <String>{});

extension OrderStatusTypeX on OrderStatusType {
  /// Отображаемое название вкладки/чипа.
  String get label {
    switch (this) {
      case OrderStatusType.pending:
        return 'На проверке';
      case OrderStatusType.confirmed:
        return 'Подтверждённый';
      case OrderStatusType.archived:
        return 'Архив';
    }
  }

  /// Перечень исходных статусов, попадающих в данную вкладку.
  Set<String> get backendKeys => _backendKeysByType[this] ?? _emptyStatusSet;

  /// Агрегированная категория (совпадает с самим перечислением).
  OrderStatusCategory get category {
    switch (this) {
      case OrderStatusType.pending:
        return OrderStatusCategory.pending;
      case OrderStatusType.confirmed:
        return OrderStatusCategory.confirmed;
      case OrderStatusType.archived:
        return OrderStatusCategory.archived;
    }
  }

  /// Проверяет, принадлежит ли исходное значение данной вкладке.
  bool matches(String? raw) => OrderStatusType.fromRaw(raw) == this;
}

final Map<String, OrderStatusType> _index = UnmodifiableMapView<String,
    OrderStatusType>(_buildIndex());

Map<String, OrderStatusType> _buildIndex() {
  final map = <String, OrderStatusType>{};
  for (final status in OrderStatusType.values) {
    for (final key in status.backendKeys) {
      map[key] = status;
    }
  }
  return map;
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
