import 'package:flutter_test/flutter_test.dart';

import 'package:bowling_market/features/search/application/search_controller.dart';
import 'package:bowling_market/features/search/domain/search_item.dart';
import 'package:bowling_market/core/repositories/search_repository.dart';

import 'test_stubs.dart';

void main() {
  late StubSearchService service;
  late SearchRepository repository;
  late SearchController controller;

  setUp(() {
    service = StubSearchService();
    repository = SearchRepository(service: service);
    controller = SearchController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('performs search and updates state', () async {
    service.setResult(
      SearchDomain.all,
      'pump',
      1,
      SearchResultPage(
        items: [
          const SearchItem(
            domain: SearchDomain.orders,
            id: '1',
            title: 'Заявка 1',
            subtitle: 'Клуб',
          ),
        ],
        page: 1,
        hasMore: false,
        totalCount: 1,
      ),
    );

    controller.updateQuery('pump', immediate: true);
    await pumpEventQueue();

    expect(controller.state.items, hasLength(1));
    expect(controller.state.totalCount, 1);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.hasError, isFalse);
  });

  test('loadMore appends results when available', () async {
    service
      ..setResult(
        SearchDomain.all,
        'order',
        1,
        const SearchResultPage(
          items: [
            SearchItem(
              domain: SearchDomain.orders,
              id: '1',
              title: 'Order 1',
              subtitle: 'First',
            ),
          ],
          page: 1,
          hasMore: true,
          totalCount: 2,
        ),
      )
      ..setResult(
        SearchDomain.all,
        'order',
        2,
        const SearchResultPage(
          items: [
            SearchItem(
              domain: SearchDomain.orders,
              id: '2',
              title: 'Order 2',
              subtitle: 'Second',
            ),
          ],
          page: 2,
          hasMore: false,
          totalCount: 2,
        ),
      );

    controller.updateQuery('order', immediate: true);
    await pumpEventQueue();
    expect(controller.state.items, hasLength(1));

    await controller.loadMore();
    await pumpEventQueue();

    expect(controller.state.items.map((e) => e.id), ['1', '2']);
    expect(controller.state.hasMore, isFalse);
  });

  test('error updates state', () async {
    service.throwErrorFor(SearchDomain.all, 'fail', 1, Exception('boom'));

    controller.updateQuery('fail', immediate: true);
    await pumpEventQueue();

    expect(controller.state.hasError, isTrue);
    expect(controller.state.items, isEmpty);
  });

  test('clearing query resets state', () async {
    service.setResult(
      SearchDomain.all,
      'text',
      1,
      const SearchResultPage(
        items: [
          SearchItem(domain: SearchDomain.clubs, id: '1', title: 'Club', subtitle: 'City'),
        ],
        page: 1,
        hasMore: false,
        totalCount: 1,
      ),
    );

    controller.updateQuery('text', immediate: true);
    await pumpEventQueue();
    expect(controller.state.items, isNotEmpty);

    controller.updateQuery('', immediate: true);
    await pumpEventQueue();

    expect(controller.state.items, isEmpty);
    expect(controller.state.isIdle, isTrue);
  });
}

