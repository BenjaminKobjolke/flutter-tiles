import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('seeded tiles open a folder and show its child', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TilesExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);

    await tester.ensureVisible(find.text('Favorites'));
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Photos'), findsNothing);
  });
}
