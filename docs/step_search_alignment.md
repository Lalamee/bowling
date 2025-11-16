# Ступенчатый поиск запчастей: стыковка фронта и бэка

## Текущее состояние
- Фронт: есть глобальный поиск (`lib/features/search/presentation/screens/global_search_screen.dart`) и поиск по складу клуба (`lib/features/clubs/presentation/screens/club_warehouse_screen.dart`), но нет мастера/степпера для выбора оборудования → узел → подузел → локация.
- Бэк: публичные эндпоинты обслуживают каталог запчастей (`/api/parts/...`) и склад (`/api/inventory/...`); остаётся добавить API дерева узлов оборудования и привязку к нему.
- DTO `PartsCatalogResponseDTO` и `PartDto` дополнены ссылками на изображения/схемы и полями узлов каталога, но пока не привязаны к реальным данным узлов — требуется сам каталог узлов.

## Что нужно добавить
1. **Дерево узлов/частей**
   - Бэк: новый эндпоинт, например `GET /api/catalog/equipment/{equipmentId}/nodes`, возвращает дерево узлов с полями `equipmentNodeId`, `parentNodeId`, `title`, `path`, `partIds` (под них уже есть поля в DTO деталей и каталога).
   - Фронт: сервис/репозиторий для загрузки дерева, состояние с шагами выбора (оборудование → узел → подузел → позиция) и экран/секция мастера внутри существующего поиска.

2. **Карточка детали**
   - Бэк: DTO (`PartsCatalogResponseDTO`, `PartDto`) уже содержат `imageUrl`, `diagramUrl`, `equipmentNodeId`, `equipmentNodePath`, `compatibility`; нужно наполнить их данными из каталога узлов и библиотеки изображений/схем. Добавить выдачу остатков по складу/клубу в том же ответе или отдельным вызовом (`GET /api/inventory/{inventoryId}/stock`).
   - Фронт: использовать существующие карточки (например, карточки деталей в `club_warehouse_screen.dart`) и добавить отображение фото/схемы, пути узлов и кнопки «Добавить в заявку» с передачей `partId` и количества в форму заявки.

3. **Интеграция со складами и заявками**
   - Бэк: убедиться, что API склада возвращает доступные/резервные остатки по клубу и что `InventorySearchRequest` поддерживает фильтр по узлу каталога (`equipmentNodeId`).
   - Фронт: при выборе детали из степпера подтягивать остатки через `InventoryRepository.getById`/поиск с `equipmentNodeId` и передавать выбранное количество в заявки (`MaintenanceRequest` / `OrderPartsRequest`).

4. **Состояния загрузки и ошибок**
   - Фронт: повторно использовать паттерн из существующих экранов (loading/error/empty в `global_search_screen.dart`) для ступенчатого поиска: индикатор загрузки дерева, пустое состояние при отсутствии деталей, отображение ошибок API через `showApiError`.

## Предлагаемые фрагменты изменений
- Бэк:
  ```java
  // Новый DTO для узлов (псевдокод)
  public class EquipmentNodeDto {
      private Long equipmentNodeId;
      private Long parentNodeId;
      private String title;
      private String path; // "Пинсеттер / Мост / ..."
      private List<Long> partIds;
  }
  ```

- Фронт:
  ```dart
  // Сервис загрузки дерева узлов (скелет)
  class EquipmentNodesRepository {
    final _dio = ApiCore().dio;

    Future<List<EquipmentNodeDto>> getNodes(int equipmentId) async {
      final res = await _dio.get('/api/catalog/equipment/$equipmentId/nodes');
      // ...маппинг в модель
    }
  }
  ```
  ```dart
  // В существующем экране поиска добавить секцию ступенчатого мастера
  Widget _buildStepSearch() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _goNext,
      onStepCancel: _goBack,
      steps: [/* оборудование, узел, подузел, позиция */],
    );
  }
  ```
  ```dart
  // Карточка детали с кнопкой "Добавить в заявку"
  ElevatedButton(
    onPressed: () => _openRequestForm(partId: part.inventoryId, defaultQty: 1),
    child: const Text('Добавить в заявку'),
  );
  ```

Эти шаги не меняют текущую архитектуру и используют существующие паттерны (репозитории Dio, экраны со состоянием загрузки/ошибки, передача параметров в формы заявок).
