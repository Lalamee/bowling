import '../../../core/models/order_status.dart';

export '../../../core/models/order_status.dart'
    show
        OrderStatusCategory,
        OrderStatusType,
        describeOrderStatus,
        isArchivedStatus,
        isConfirmedStatus,
        isPendingStatus,
        kOrderStatusFilterOrder,
        mapOrderStatusCategory,
        orderStatusCategoryLabel;

// Алиасы сохранены для совместимости со старым кодом.
OrderStatusCategory mapOrderStatus(String? rawStatus) =>
    mapOrderStatusCategory(rawStatus);

String orderStatusLabel(OrderStatusCategory category) =>
    orderStatusCategoryLabel(category);

String orderStatusLabelFromRaw(String? rawStatus) =>
    orderStatusLabel(mapOrderStatus(rawStatus));
