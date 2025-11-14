# План по реализации блока «Приёмка поставок → частичная приёмка → архив → оценка → претензии»

## 1. Текущее состояние

* **Бэкенд** хранит сущности `PurchaseOrder`, `RequestPart` и `SupplierReview`, но:
  * Заказ (`PurchaseOrder`) описывает только поставщика, заявку и даты, не содержит клуба, статусов приёмки и признаков отзывов (`backend/src/main/java/ru/bowling/bowlingapp/Entity/PurchaseOrder.java`).
  * Позиции заявки (`RequestPart`) не имеют фактически принятого количества, отдельного статуса приёмки и обязательных причин отказа (`backend/src/main/java/ru/bowling/bowlingapp/Entity/RequestPart.java`).
  * Модель `SupplierReview` не используется в сервисах/контроллерах для отзывов и претензий (`backend/src/main/java/ru/bowling/bowlingapp/Entity/SupplierReview.java`).
  * `SupplierService` умеет только создавать заказ, отсутствуют операции частичной приёмки, архивирования или отзывов (`backend/src/main/java/ru/bowling/bowlingapp/Service/SupplierService.java`).
  * Склады обслуживает `InventoryController`, но нет вызова обновления склада после приёмки (`backend/src/main/java/ru/bowling/bowlingapp/Controller/InventoryController.java`).
* **Фронтенд** выводит историю заявок менеджера (`frontend/lib/features/orders/presentation/screens/manager_orders_history_screen.dart`), но не содержит экранов приёмки поставок, архива, рейтингов и претензий.
  * Репозиторий `MaintenanceRepository` работает только с `/api/maintenance/requests/*` (`frontend/lib/core/repositories/maintenance_repository.dart`).
  * DTO `MaintenanceRequestResponseDto` не содержит данных о приёмке и поставщике (`frontend/lib/models/maintenance_request_response_dto.dart`).

> Итог: блок «Приёмка поставок» отсутствует целиком; нужно расширять модели, API и UI.

## 2. Требуемые изменения (по файлам и сущностям)

### Бэкенд

1. **Сущности и DTO**
   * `PurchaseOrder.java` — добавить поля `BowlingClub club`, `Long acceptedByUserId`, `LocalDateTime closedAt`, `PurchaseOrderStatus finalStatus`, `boolean hasReview`, `boolean hasComplaint`. Если клуб не проставляется — добавить TODO с описанием необходимости брать клуб из `MaintenanceRequest`.
   * `RequestPart.java` — расширить полями `Integer acceptedQuantity`, `AcceptanceStatus acceptanceStatus`, `String acceptanceComment`, `String complaintNotes`. Обязательно сохранять причину для статусов `PARTIAL/REJECTED`.
   * Создать DTO: `PurchaseOrderDTO`, `PurchaseOrderDetailsDTO`, `PurchaseOrderItemDTO`, `PurchaseOrderAcceptanceDTO`, `PurchaseOrderArchiveFilter`, `SupplierReviewDTO`, `PurchaseOrderComplaintDTO`.
   * TODO: описать контракт `InventoryReceiptItemDTO` для обновления склада (`warehouseId`, `catalogId`, `quantityDelta`).

2. **Репозитории**
   * `PurchaseOrderRepository` — методы `findByClub_ClubIdAndStatusIn`, `findByStatusInAndHasComplaint`, `findByMaintenanceRequest_RequestId`.
   * `RequestPartRepository` — `findByPurchaseOrder_OrderId` и `saveAll` для батч-обновления статусов/количеств.
   * Создать `SupplierReviewRepository` с CRUD по `supplierId`, `purchaseOrderId`, фильтрацией `isComplaint`.

3. **Сервисы**
   * `PurchaseOrderService` (новый класс):
     * `List<PurchaseOrderDTO> getPendingOrders(Long clubId)` — список ожидающих приёмку.
     * `PurchaseOrderDetailsDTO getOrderDetails(Long orderId)` — детали с позициями, поставщиком, контактами.
     * `PurchaseOrderDetailsDTO acceptOrder(Long orderId, PurchaseOrderAcceptanceDTO payload)` — частичная приёмка (рассчитывает агрегированный статус, обновляет склад через `InventoryService.applyReceipt`).
     * `Page<PurchaseOrderDTO> getArchive(PurchaseOrderArchiveFilter filter)` — архив с фильтрами по клубу/поставщику/статусу/претензиям.
     * `SupplierReviewDTO leaveReview(Long orderId, SupplierReviewDTO dto)` и `SupplierReviewDTO fileComplaint(Long orderId, PurchaseOrderComplaintDTO dto)` — работа с отзывами/претензиями.
   * `InventoryService`/`InventoryServiceImpl` — добавить `applyReceipt(Long clubId, List<InventoryReceiptItemDTO> items)` (TODO: если склад обособлен по warehouseId, переводить `clubId` в `warehouseId`).
   * `SupplierService` — использовать `PurchaseOrderService` или делегировать в него создание/обновление заказов.

4. **Контроллеры**
   * Новый `PurchaseOrderController` (`@RequestMapping("/api/purchase-orders")`):
     * `GET /pending?clubId=&status=` — список для экрана приёмки.
     * `GET /{orderId}` — детали.
     * `POST /{orderId}/accept` — payload частичной приёмки.
     * `GET /archive` — архив.
     * `POST /{orderId}/review` и `POST /{orderId}/complaints` — оценка и претензии.
     * `PUT /complaints/{id}` — смена статуса претензии (черновик/отправлена/в работе/закрыта).
   * `InventoryController` — при необходимости добавить endpoint `POST /warehouse/{clubId}/apply-receipt` (если не хотим вызывать сервис напрямую из `PurchaseOrderController`).

5. **Мапперы и DTO для существующих эндпоинтов**
   * Расширить `MaintenanceRequestResponseDTO` (и маппинг в `MaintenanceRequestService`) полями `supplierName`, `supplierInn`, `deliveryDate`, `hasPurchaseOrder`, чтобы старые экраны могли показывать связь заявки ↔ поставки.
   * TODO: обновить `API_DOCUMENTATION.md` с описанием новых эндпоинтов.

### Фронтенд

1. **API слой**
   * `api/api_service.dart` — добавить методы:
     * `Future<List<PurchaseOrderDto>> getPurchaseOrders({int? clubId, String? status});`
     * `Future<PurchaseOrderDetailsDto> getPurchaseOrderDetails(int orderId);`
     * `Future<PurchaseOrderDetailsDto> acceptPurchaseOrder(int orderId, PurchaseOrderAcceptanceRequest body);`
     * `Future<List<PurchaseOrderDto>> getPurchaseOrdersArchive({...});`
     * `Future<void> submitSupplierReview(int orderId, SupplierReviewRequest body);`
     * `Future<void> createOrderComplaint(int orderId, OrderComplaintRequest body);`
     * `Future<void> updateOrderComplaint(int complaintId, OrderComplaintRequest body);`
   * Создать `core/repositories/purchase_orders_repository.dart`, который инкапсулирует эти вызовы и кэширует фильтры.

2. **Модели**
   * Добавить DTO в `frontend/lib/models`: `purchase_order_dto.dart`, `purchase_order_details_dto.dart`, `purchase_order_item_dto.dart`, `purchase_order_acceptance_request.dart`, `supplier_review_dto.dart`, `order_complaint_dto.dart`.
   * Расширить `maintenance_request_response_dto.dart` новыми полями (`supplierInn`, `supplierContact`, `hasPurchaseOrder`, `acceptedQuantity`, `acceptanceStatus`). До тех пор, пока бэк не вернёт значения — показывать плейсхолдеры и оставить TODO.

3. **Экраны и виджеты**
   * Новый экран `features/orders/presentation/screens/supply_acceptance_screen.dart` — список ожидающих поставок. Использовать паттерн загрузки/ошибок/пустого состояния из `manager_orders_history_screen.dart`.
   * Экран `supply_order_details_screen.dart` с формой частичной приёмки: таблица позиций, поля ввода количества, селектор статуса (принято/частично/отказ) и обязательный `TextField` для причин.
   * Раздел архива `supply_orders_archive_screen.dart` с фильтрами по клубу/поставщику/статусу, сортировкой по дате закрытия и бейджами «Есть оценка», «Есть претензия».
   * Диалоги `supplier_review_dialog.dart` и `order_complaint_dialog.dart` в `features/orders/presentation/dialogs`.
   * Виджеты:
     * `PurchaseOrderCard` (общая информация, статусы, действия) в `features/orders/presentation/widgets`.
     * `PurchaseOrderItemRow` — элемент формы приёмки.
     * `PurchaseOrderFiltersBar` — фильтры по клубу/статусу/поставщику.

4. **Навигация и роутинг**
   * Добавить маршруты в `core/routing/routes.dart` (например, `Routes.supplyAcceptance`, `Routes.supplyOrderDetails`, `Routes.supplyOrdersArchive`).
   * В `manager_orders_history_screen.dart` или профиле менеджера добавить CTA «Приёмка поставок».

5. **Состояния и обработка ошибок**
   * Использовать уже принятые паттерны `showApiError`, `RefreshIndicator` и `AppBottomNav`.
   * При частичной приёмке валидировать обязательные поля: если статус `PARTIAL/REJECTED` — причина не может быть пустой. Добавить локальную проверку и подсветку ошибок.
   * После успешной приёмки обновлять список и показывать `SnackBar`.

6. **Оценки и претензии**
   * После закрытия заказа показывать кнопку «Оценить поставщика» и «Создать претензию». Оценка — числовой рейтинг (1–5) с обязательным комментарием при `rating <= 2` (TODO в коде).
   * Претензия — диалог выбора спорных позиций и текстового описания, статус отображается на карточке архива (иконки/бейджи).
   * Отображать отзывы в деталях архива и в карточке поставщика (когда такой экран будет подключён).

7. **TODO на фронте**
   * Если бэк пока не возвращает `supplierInn`/контакты, оставить TODO-комментарии рядом с UI.
   * Если эндпоинт обновления склада ещё не готов, логировать предупреждение после успешной приёмки.

## 3. Примерные фрагменты кода

### Бэкенд: DTO и сервис
```java
// backend/src/main/java/ru/bowling/bowlingapp/DTO/PurchaseOrderAcceptanceDTO.java
@Data
public class PurchaseOrderAcceptanceDTO {
    private Long orderId;
    private Long clubId;
    private Long acceptedByUserId;
    private String managerComment;
    private List<PurchaseOrderItemDTO> items;
}

@Data
public class PurchaseOrderItemDTO {
    private Long partId;
    private Integer expectedQuantity;
    private Integer acceptedQuantity;
    private AcceptanceStatus status; // ACCEPTED, PARTIAL, REJECTED
    private String reason;
}
```

```java
// backend/src/main/java/ru/bowling/bowlingapp/Service/PurchaseOrderService.java
@Transactional
public PurchaseOrderDetailsDTO acceptOrder(Long orderId, PurchaseOrderAcceptanceDTO payload) {
    PurchaseOrder order = purchaseOrderRepository.findById(orderId)
        .orElseThrow(() -> new EntityNotFoundException("Order not found"));

    Map<Long, RequestPart> partsById = order.getOrderedParts().stream()
        .collect(Collectors.toMap(RequestPart::getPartId, Function.identity()));

    payload.getItems().forEach(item -> {
        RequestPart part = partsById.get(item.getPartId());
        if (part == null) {
            throw new IllegalArgumentException("Part " + item.getPartId() + " not found");
        }
        part.setAcceptedQuantity(item.getAcceptedQuantity());
        part.setAcceptanceStatus(item.getStatus());
        part.setRejectionReason(item.getReason());
    });

    order.setStatus(resolveStatus(order.getOrderedParts()));
    order.setActualDeliveryDate(LocalDateTime.now());
    order.setClosedAt(LocalDateTime.now());
    order.setAcceptedByUserId(payload.getAcceptedByUserId());

    purchaseOrderRepository.save(order);
    inventoryService.applyReceipt(order.getClub().getClubId(), buildReceipt(order.getOrderedParts()));
    return mapper.toDetails(order);
}
```

### Фронтенд: репозиторий и экран приёмки
```dart
// frontend/lib/core/repositories/purchase_orders_repository.dart
class PurchaseOrdersRepository {
  final ApiService _api = ApiService();

  Future<List<PurchaseOrderDto>> pending({int? clubId}) =>
      _api.getPurchaseOrders(clubId: clubId, status: 'PENDING_ACCEPTANCE');

  Future<PurchaseOrderDetailsDto> details(int orderId) =>
      _api.getPurchaseOrderDetails(orderId);

  Future<PurchaseOrderDetailsDto> accept(
    int orderId,
    PurchaseOrderAcceptanceRequest request,
  ) => _api.acceptPurchaseOrder(orderId, request);

  Future<List<PurchaseOrderDto>> archive({
    int? clubId,
    String? supplier,
    String? status,
    bool? hasComplaint,
    bool? hasReview,
  }) => _api.getPurchaseOrdersArchive(
        clubId: clubId,
        supplier: supplier,
        status: status,
        hasComplaint: hasComplaint,
        hasReview: hasReview,
      );
}
```

```dart
// frontend/lib/features/orders/presentation/screens/supply_order_details_screen.dart
class SupplyOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const SupplyOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<SupplyOrderDetailsScreen> createState() => _SupplyOrderDetailsScreenState();
}

class _SupplyOrderDetailsScreenState extends State<SupplyOrderDetailsScreen> {
  final PurchaseOrdersRepository _repository = PurchaseOrdersRepository();
  late Future<PurchaseOrderDetailsDto> _future;
  final Map<int, PurchaseOrderItemFormState> _items = {};
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.details(widget.orderId);
  }

  Future<void> _submit() async {
    final invalid = _items.values.any((item) => !item.isValid);
    if (invalid) {
      showToast(context, 'Заполните причины для отказанных позиций');
      return;
    }
    setState(() => _submitting = true);
    try {
      final request = PurchaseOrderAcceptanceRequest(
        acceptedBy: currentUserId,
        clubId: selectedClubId,
        comment: _commentController.text.trim().nullIfEmpty,
        items: _items.values.map((item) => item.toDto()).toList(),
      );
      await _repository.accept(widget.orderId, request);
      if (!mounted) return;
      Navigator.pop(context, SupplyAcceptanceResult.accepted);
    } catch (e) {
      showApiError(context, e);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Приёмка поставки')),
      body: FutureBuilder<PurchaseOrderDetailsDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateWidget(onRetry: () => setState(() {
                  _future = _repository.details(widget.orderId);
                }));
          }
          return SupplyAcceptanceForm(
            order: snapshot.data!,
            commentController: _commentController,
            items: _items,
            submitting: _submitting,
            onChanged: () => setState(() {}),
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}
```

### Диалог оценки и претензии (фрагменты)
```dart
Future<void> showSupplierReviewDialog(BuildContext context, PurchaseOrderDto order) {
  final controller = TextEditingController();
  int rating = 5;
  return showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar(
            initialRating: rating.toDouble(),
            onChanged: (value) => rating = value.round(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Комментарий'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (rating <= 2 && controller.text.trim().isEmpty) {
                showToast(context, 'Комментарий обязателен при низкой оценке');
                return;
              }
              Navigator.pop(context, SupplierReviewInput(
                orderId: order.orderId,
                rating: rating,
                comment: controller.text.trim().nullIfEmpty,
              ));
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
}
```

```dart
class OrderComplaintDialog extends StatefulWidget {
  final PurchaseOrderDetailsDto order;
  const OrderComplaintDialog({super.key, required this.order});

  @override
  State<OrderComplaintDialog> createState() => _OrderComplaintDialogState();
}

class _OrderComplaintDialogState extends State<OrderComplaintDialog> {
  final Map<int, bool> _selected = {};
  final Map<int, TextEditingController> _reasons = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Претензия'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.order.items.map((item) {
            final selected = _selected[item.partId] ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: selected,
                  onChanged: (value) => setState(() => _selected[item.partId] = value ?? false),
                  title: Text('${item.partName} · ${item.acceptedQuantity}/${item.expectedQuantity}'),
                  subtitle: Text(item.acceptanceStatusLabel),
                ),
                if (selected)
                  TextField(
                    controller: _reasons.putIfAbsent(item.partId, () => TextEditingController()),
                    decoration: const InputDecoration(labelText: 'Причина'),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            final payload = _selected.entries
                .where((entry) => entry.value)
                .map((entry) => ComplaintItem(
                      partId: entry.key,
                      reason: _reasons[entry.key]?.text,
                    ))
                .toList();
            if (payload.isEmpty) {
              showToast(context, 'Выберите хотя бы одну позицию');
              return;
            }
            Navigator.pop(context, payload);
          },
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}
```

### TODO-пример
```dart
// TODO: backend должен вернуть supplierInn и контакт, чтобы отобразить его в шапке заказа
Text(order.supplierInn ?? '—');
```

```java
// TODO(b/backend): требуется endpoint для applyReceipt(clubId, items)
clubWarehouseService.applyReceipt(order.getClub().getClubId(), receiptItems);
```

## 4. Следующие шаги
1. Согласовать контракт DTO/эндпоинтов между командами.
2. Обновить `API_DOCUMENTATION.md` и `README.md` после появления API.
3. Реализовать и протестировать сервисы/экраны по описанному плану.
