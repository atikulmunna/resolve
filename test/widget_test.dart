import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resolve/data/habit_store.dart';
import 'package:resolve/features/home/home_screen.dart';

void main() {
  testWidgets('Home renders the streak day count', (tester) async {
    final store = HabitStore.sample();
    await tester.pumpWidget(MaterialApp(home: HomeScreen(store: store)));
    await tester.pump();

    // The habit name and the DAYS label are present on Home.
    expect(find.text('No Social Media'), findsOneWidget);
    expect(find.text('DAYS'), findsWidgets);
  });
}
