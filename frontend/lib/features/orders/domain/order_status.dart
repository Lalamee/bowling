enum OrderStatusCategory { pending, confirmed, archived }

const Set<String> _archiveStatuses = {
  'DONE',
  'COMPLETED',
  'CLOSED',
  'UNREPAIRABLE',
  'REJECTED',
};

const Set<String> _confirmedStatuses = {
  'APPROVED',
  'IN_PROGRESS',
};

OrderStatusCategory mapOrderStatus(String? rawStatus) {
  final normalized = rawStatus?.trim().toUpperCase() ?? '';

  if (_archiveStatuses.contains(normalized)) {
    return OrderStatusCategory.archived;
  }

  if (_confirmedStatuses.contains(normalized)) {
    return OrderStatusCategory.confirmed;
  }

  return OrderStatusCategory.pending;
}

String orderStatusLabel(OrderStatusCategory category) {
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

String orderStatusLabelFromRaw(String? rawStatus) {
  return orderStatusLabel(mapOrderStatus(rawStatus));
}

bool isArchivedStatus(String? rawStatus) => mapOrderStatus(rawStatus) == OrderStatusCategory.archived;

bool isConfirmedStatus(String? rawStatus) => mapOrderStatus(rawStatus) == OrderStatusCategory.confirmed;

bool isPendingStatus(String? rawStatus) => mapOrderStatus(rawStatus) == OrderStatusCategory.pending;
