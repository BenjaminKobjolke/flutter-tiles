import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  const entry = LauncherEntry(
    id: '1',
    folderPath: '/old',
    label: 'Tile',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF000000,
    sortOrder: 0,
    createdAtMs: 0,
  );

  Future<Object? Function()> open(
    WidgetTester tester,
    LauncherEditorConfig editor,
  ) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async =>
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => LauncherTileEditScreen(
                        entry: entry,
                        allEntries: const [entry],
                        editor: editor,
                      ),
                    ),
                  ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('host settings are absent without a builder', (tester) async {
    await open(tester, const LauncherEditorConfig());
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Return to launcher on back'), findsNothing);
  });

  testWidgets('host settings draft changes return on save', (tester) async {
    final result = await open(
      tester,
      LauncherEditorConfig(
        settingsSectionBuilder: (context, entry, draft, onChanged) =>
            ElevatedButton(
              onPressed: () {
                draft.folderPath = '/new';
                draft.extras['target'] = '123';
                onChanged();
              },
              child: const Text('Change target'),
            ),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Change target'));
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final edit = result() as LauncherTileEditResult;
    expect(edit.folderPath, '/new');
    expect(edit.extras, {'target': '123'});
  });

  testWidgets('host may show return toggle', (tester) async {
    await open(tester, const LauncherEditorConfig(showReturnToggle: true));
    await tester.ensureVisible(find.text('Return to launcher on back'));
    expect(find.text('Return to launcher on back'), findsOneWidget);
  });

  testWidgets('icon picker result is ignored after editor is removed', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    late Route<Object?> editorRoute;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                editorRoute = MaterialPageRoute<Object?>(
                  builder: (_) => const LauncherTileEditScreen(
                    entry: entry,
                    allEntries: [entry],
                  ),
                );
                navigatorKey.currentState!.push<Object?>(editorRoute);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pick Icon'));
    await tester.tap(find.text('Pick Icon'));
    await tester.pumpAndSettle();
    navigatorKey.currentState!.removeRoute(editorRoute);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(IconPickerDialog),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LauncherTileEditScreen), findsNothing);
  });
}
