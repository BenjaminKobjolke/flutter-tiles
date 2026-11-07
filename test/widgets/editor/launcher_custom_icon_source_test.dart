import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

const _entry = LauncherEntry(
  id: '1',
  folderPath: '/old',
  label: 'Tile',
  action: 'openFolder',
  iconName: 'folder',
  backgroundColor: 0xFF000000,
  sortOrder: 0,
  createdAtMs: 0,
);

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg==',
);

void main() {
  Future<Object? Function()> open(
    WidgetTester tester, {
    LauncherEditorConfig editor = const LauncherEditorConfig(),
    LauncherEntry entry = _entry,
  }) async {
    Object? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute(
                    builder: (_) => LauncherTileEditScreen(
                      entry: entry,
                      allEntries: [entry],
                      editor: editor,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return () => popped;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save').first);
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();
  }

  LauncherCustomIconSource source(
    Future<Uint8List?> Function(BuildContext, LauncherTileSettingsDraft) load,
  ) => LauncherCustomIconSource(
    label: 'Get icon',
    icon: Icons.download,
    load: load,
  );

  testWidgets('button is hidden without a source', (tester) async {
    await open(tester);
    expect(find.text('Get icon'), findsNothing);
  });

  testWidgets('button is hidden when the hook returns null', (tester) async {
    await open(
      tester,
      editor: LauncherEditorConfig(customIconSource: (_) => null),
    );
    expect(find.text('Get icon'), findsNothing);
  });

  testWidgets('button follows Pick Icon and hook receives the edited entry', (
    tester,
  ) async {
    LauncherEntry? received;
    await open(
      tester,
      editor: LauncherEditorConfig(
        customIconSource: (entry) {
          received = entry;
          return source((_, _) async => null);
        },
      ),
    );

    final pick = tester.getTopLeft(find.text('Pick Icon')).dy;
    final custom = tester.getTopLeft(find.text('Get icon')).dy;
    expect(custom, greaterThan(pick));
    expect(received, same(_entry));
  });

  testWidgets('loading disables the button and receives the live draft', (
    tester,
  ) async {
    final pending = Completer<Uint8List?>();
    var calls = 0;
    String? loadedUrl;
    await open(
      tester,
      editor: LauncherEditorConfig(
        settingsSectionBuilder: (_, __, draft, onChanged) => TextButton(
          onPressed: () {
            draft.extras['url'] = 'https://example.test';
            onChanged();
          },
          child: const Text('Edit URL'),
        ),
        customIconSource: (_) => source((_, draft) {
          calls++;
          loadedUrl = draft.extras['url'];
          return pending.future;
        }),
      ),
    );

    await tester.tap(find.text('Edit URL'));
    await tester.tap(find.text('Get icon'));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Get icon'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Get icon'),
          matching: find.byType(OutlinedButton),
        ),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Get icon'), warnIfMissed: false);
    expect(calls, 1);
    expect(loadedUrl, 'https://example.test');

    pending.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'loaded bytes preview, dirty prompt, and save result retain them',
    (tester) async {
      final popped = await open(
        tester,
        editor: LauncherEditorConfig(
          customIconSource: (_) => source((_, _) async => _png),
        ),
      );

      await tester.tap(find.text('Get icon'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(LauncherTileEditScreen),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Save'),
        ),
      );
      await tester.pumpAndSettle();

      final result = popped() as LauncherTileEditResult;
      expect(result.applyTo(_entry).customIconBase64, base64Encode(_png));
    },
  );

  testWidgets('null result leaves the icon unchanged and screen clean', (
    tester,
  ) async {
    final popped = await open(
      tester,
      editor: LauncherEditorConfig(
        customIconSource: (_) => source((_, _) async => null),
      ),
    );
    await tester.tap(find.text('Get icon'));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Get icon'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
    expect(popped(), isNull);

    final savedEntry = _entry.copyWith(customIconBase64: base64Encode(_png));
    final savedPopped = await open(
      tester,
      entry: savedEntry,
      editor: LauncherEditorConfig(
        customIconSource: (_) => source((_, _) async => null),
      ),
    );
    await tester.tap(find.text('Get icon'));
    await tester.pumpAndSettle();
    await save(tester);
    final saved = savedPopped() as LauncherTileEditResult;
    expect(saved.applyTo(savedEntry).customIconBase64, base64Encode(_png));
  });

  testWidgets('picking a Font Awesome icon after loading clears the bitmap', (
    tester,
  ) async {
    final popped = await open(
      tester,
      editor: LauncherEditorConfig(
        customIconSource: (_) => source((_, _) async => _png),
      ),
    );
    await tester.tap(find.text('Get icon'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pick Icon'));
    await tester.tap(find.text('Pick Icon'));
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
    await save(tester);

    final result = popped() as LauncherTileEditResult;
    expect(result.clearCustomIcon, isFalse);
    expect(result.customIconBase64, isNull);
    expect(result.applyTo(_entry).customIconBase64, isNull);
  });
}
