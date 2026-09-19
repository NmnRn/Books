import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_tracker/main.dart';

void main() {
  testWidgets('Uygulama açılır ve alt menü sekmeleri görünür', (tester) async {
    await tester.pumpWidget(const BookTrackerApp());
    await tester.pump();

    // Alt gezinme çubuğu sekmeleri.
    expect(find.text('Kitaplar'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);
    expect(find.text('Zamanlayıcı'), findsOneWidget);

    // İlk açılışta Kitaplığım ekranı görünür.
    expect(find.text('Kitaplığım'), findsOneWidget);
  });
}
