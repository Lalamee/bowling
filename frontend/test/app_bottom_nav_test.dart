import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/shared/widgets/nav/app_bottom_nav.dart';

void main() {
  testWidgets('AppBottomNav renders all tabs and propagates taps', (tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AppBottomNav(
          currentIndex: 1,
          onTap: (index) => tappedIndex = index,
        ),
      ),
    ));

    expect(find.text('Заказы'), findsOneWidget);
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Клуб'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(tappedIndex, equals(1));
  });
}
