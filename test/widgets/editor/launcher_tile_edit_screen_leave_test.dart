import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

const _entry = LauncherEntry(
  id: '1',
  folderPath: '/fake',
  label: 'Camera',
  action: 'openFolder',
  iconName: 'folder',
  backgroundColor: 0xFF000000,
  sortOrder: 0,
  createdAtMs: 0,
);

/// Sentinel: the editor route never popped.
const _notPopped = Object();

void main() {
  /// Pumps the host, opens the editor and returns a getter for the pop value.
  Future<Object? Function()> openEditor(WidgetTester tester) async {
    Object? popped = _notPopped;
    await tester.pumpWidget(_Host(onPopped: (v) => popped = v));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => popped;
  }

  Future<void> togglePin(WidgetTester tester) async {
    final pin = find.byType(SwitchListTile).last;
    await tester.ensureVisible(pin);
    await tester.pumpAndSettle();
    await tester.tap(pin);
    await tester.pump();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  Finder dialogTitle() => find.text('Unsaved changes');

  testWidgets('untouched screen pops on back without a dialog', (tester) async {
    final popped = await openEditor(tester);
    await back(tester);

    expect(dialogTitle(), findsNothing);
    expect(popped(), isNull);
  });

  testWidgets('dirty screen shows dialog; Cancel keeps it open', (
    tester,
  ) async {
    final popped = await openEditor(tester);
    await togglePin(tester);
    await back(tester);

    expect(dialogTitle(), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Save'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(dialogTitle(), findsNothing);
    expect(find.byType(LauncherTileEditScreen), findsOneWidget);
    expect(popped(), same(_notPopped));
  });

  testWidgets('dirty screen + Discard pops with null', (tester) async {
    final popped = await openEditor(tester);
    await togglePin(tester);
    await back(tester);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(LauncherTileEditScreen), findsNothing);
    expect(popped(), isNull);
  });

  testWidgets('dirty screen + Save pops with the edited result', (
    tester,
  ) async {
    final popped = await openEditor(tester);
    await togglePin(tester);
    await back(tester);

    // The dialog's Save button, not the AppBar action behind the barrier.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LauncherTileEditScreen), findsNothing);
    final result = popped();
    expect(result, isA<LauncherTileEditResult>());
    expect((result as LauncherTileEditResult).pinned, isTrue);
  });
}

/// Host page with an "open" button that pushes the editor and reports the
/// value it popped with.
class _Host extends StatelessWidget {
  final ValueChanged<Object?> onPopped;

  const _Host({required this.onPopped});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => const LauncherTileEditScreen(
                    entry: _entry,
                    allEntries: [_entry],
                  ),
                ),
              );
              onPopped(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}
