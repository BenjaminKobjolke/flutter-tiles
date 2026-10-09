import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  const tile = LauncherEntry(
    id: '1',
    folderPath: '',
    label: 'Camera',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF000000,
    sortOrder: 0,
    createdAtMs: 0,
  );
  const folder = LauncherEntry(
    id: '2',
    folderPath: '',
    label: 'Albums',
    action: LauncherEntry.folderAction,
    iconName: 'folder',
    backgroundColor: 0xFF000000,
    sortOrder: 1,
    createdAtMs: 0,
  );

  testWidgets('tile semantics use the label', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = false;
    var longPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 120,
            child: LauncherTileWidget(
              entry: tile,
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(LauncherTileWidget)),
      matchesSemantics(
        label: 'Camera',
        isButton: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    final semantics = tester.getSemantics(find.byType(LauncherTileWidget));
    semantics.owner!.performAction(semantics.id, SemanticsAction.tap);
    semantics.owner!.performAction(semantics.id, SemanticsAction.longPress);
    await tester.pump();
    expect(tapped, isTrue);
    expect(longPressed, isTrue);
    handle.dispose();
  });

  testWidgets('folder semantics include child count', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 120,
            child: LauncherTileWidget(entry: folder, folderChildCount: 3),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(LauncherTileWidget)),
      matchesSemantics(label: 'Albums, 3 items', isButton: true),
    );
    handle.dispose();
  });
}
