import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

LauncherEntry _entry(
  String id,
  String label, {
  required bool isFolder,
  String? parentId,
}) =>
    LauncherEntry(
      id: id,
      folderPath: '',
      label: label,
      action: isFolder ? LauncherEntry.folderAction : 'openFolder',
      iconName: 'folder',
      backgroundColor: 0xFF000000,
      sortOrder: 0,
      createdAtMs: 0,
      parentId: parentId,
    );

void main() {
  // Work → Sub (nested); Photos at the root; a normal tile that must never be
  // offered as a target.
  final all = <LauncherEntry>[
    _entry('1', 'Work', isFolder: true),
    _entry('2', 'Photos', isFolder: true),
    _entry('3', 'SomeTile', isFolder: false),
    _entry('4', 'Sub', isFolder: true, parentId: '1'),
  ];

  /// Registers prefs, pumps a screen with an "open" button, and taps it so the
  /// picker is shown. Selections land in the returned holder list.
  Future<List<LauncherFolderPick?>> pumpAndOpen(
    WidgetTester tester, {
    List<LauncherEntry>? entries,
    String? excludeFolderId,
  }) async {
    final picked = <LauncherFolderPick?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked.add(
                  await LauncherFolderPickerDialog.show(
                    context,
                    allEntries: entries ?? all,
                    excludeFolderId: excludeFolderId,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('starts at root: shows only root folders, no tiles, no flat '
      'ancestor labels', (tester) async {
    await pumpAndOpen(tester);

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    // Nested folder not shown at the root level, nor as a flat "Work / Sub".
    expect(find.text('Sub'), findsNothing);
    expect(find.textContaining('Work / Sub'), findsNothing);
    // Non-folder tiles are not destinations.
    expect(find.text('SomeTile'), findsNothing);
  });

  testWidgets('drilling in shows children and confirm returns the folder',
      (tester) async {
    final picked = await pumpAndOpen(tester);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(find.text('Sub'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(picked.single?.parentId, '1');
    expect(picked.single?.label, 'Work');
  });

  testWidgets('confirming at root returns a null parentId', (tester) async {
    final picked = await pumpAndOpen(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(picked.single, isNotNull);
    expect(picked.single?.parentId, isNull);
    expect(picked.single?.label, 'Root level');
  });

  testWidgets('cancel returns null', (tester) async {
    final picked = await pumpAndOpen(tester);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(picked.single, isNull);
  });

  testWidgets('back goes up one level and is disabled at root',
      (tester) async {
    await pumpAndOpen(tester);

    final back = find.widgetWithIcon(IconButton, Icons.arrow_back);
    expect(tester.widget<IconButton>(back).onPressed, isNull);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(back).onPressed, isNotNull);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Photos'), findsOneWidget);
    expect(tester.widget<IconButton>(back).onPressed, isNull);
  });

  testWidgets('empty level shows the empty label and a count badge renders',
      (tester) async {
    await pumpAndOpen(tester);

    // Work contains exactly one entry (Sub) — badge shows "1".
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Work'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // Sub itself is empty — drilling into it shows the empty label.
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sub'));
    await tester.pumpAndSettle();
    expect(find.text('Empty folder'), findsOneWidget);
  });

  testWidgets('search flat-filters folders by name across levels',
      (tester) async {
    await pumpAndOpen(tester);

    await tester.enterText(find.byType(TextField), 'Sub');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Sub'), findsOneWidget);
  });

  testWidgets('excludeFolderId hides the folder and its descendants',
      (tester) async {
    await pumpAndOpen(tester, excludeFolderId: '1');

    expect(find.text('Work'), findsNothing);
    expect(find.text('Photos'), findsOneWidget);

    // Sub is Work's child: not reachable at root, nor via search.
    await tester.enterText(find.byType(TextField), 'Sub');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Sub'), findsNothing);
  });

  group('applyTo', () {
    test('a folder destination sets the entry parentId', () {
      const pick = LauncherFolderPick(parentId: '2', label: 'Photos');

      expect(pick.applyTo(_entry('3', 'Tile', isFolder: false)).parentId, '2');
    });

    test('the root destination clears an existing parentId', () {
      const pick = LauncherFolderPick(parentId: null, label: 'Root');
      final inFolder =
          _entry('3', 'Tile', isFolder: false).copyWith(parentId: '2');

      expect(pick.applyTo(inFolder).parentId, isNull);
    });
  });
}
