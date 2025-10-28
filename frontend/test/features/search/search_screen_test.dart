import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bowling_market/features/search/presentation/screens/global_search_screen.dart';
import 'package:bowling_market/features/search/domain/search_item.dart';
import 'package:bowling_market/core/repositories/search_repository.dart';

import 'test_stubs.dart';

void main() {
  testWidgets('search screen shows loader then results', (tester) async {
    final service = StubSearchService()
      ..setResult(
        SearchDomain.all,
        'order',
        1,
        const SearchResultPage(
          items: [
            SearchItem(
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
    final repository = SearchRepository(service: service);

    await tester.pumpWidget(MaterialApp(home: GlobalSearchScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Введите запрос, чтобы начать поиск'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'order');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.text('Заявка 1'), findsOneWidget);
  });

  testWidgets('domain chip triggers domain-specific search', (tester) async {
    final service = StubSearchService()
      ..setResult(
        SearchDomain.all,
        'club',
        1,
        const SearchResultPage(
          items: [
            SearchItem(
              domain: SearchDomain.clubs,
              id: '10',
              title: 'Bowling City',
              subtitle: 'Город',
            ),
          ],
          page: 1,
          hasMore: false,
          totalCount: 1,
        ),
      )
      ..setResult(
        SearchDomain.clubs,
        'club',
        1,
        const SearchResultPage(
          items: [
            SearchItem(
              domain: SearchDomain.clubs,
              id: '10',
              title: 'Bowling City',
              subtitle: 'Город',
            ),
          ],
          page: 1,
          hasMore: false,
          totalCount: 1,
        ),
      );
    final repository = SearchRepository(service: service);

    await tester.pumpWidget(MaterialApp(home: GlobalSearchScreen(repository: repository)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'club');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Bowling City'), findsOneWidget);

    await tester.tap(find.text('Клубы'));
    await tester.pumpAndSettle();

    expect(find.text('Bowling City'), findsOneWidget);
  });
}
