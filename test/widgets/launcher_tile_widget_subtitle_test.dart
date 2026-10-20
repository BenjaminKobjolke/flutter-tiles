import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  const entry = LauncherEntry(
    id: 'tile',
    folderPath: '',
    label: 'A launcher tile',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF000000,
    sortOrder: 0,
    createdAtMs: 0,
  );

  Future<void> pumpTile(WidgetTester tester, LauncherEntry value) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: LauncherTileWidget(entry: value),
          ),
        ),
      ),
    );
  }

  testWidgets('null and empty subtitles do not build a second text row', (
    tester,
  ) async {
    for (final subtitle in <String?>[null, '']) {
      await pumpTile(tester, entry.copyWith(subtitle: subtitle));
      expect(
        find.descendant(
          of: find.byType(LauncherTileWidget),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('subtitle is a smaller single ellipsized line', (tester) async {
    await pumpTile(tester, entry.copyWith(subtitle: 'Owning project'));

    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(LauncherTileWidget),
        matching: find.byType(Text),
      ),
    );
    expect(
      texts.map((text) => text.data),
      containsAll(['A launcher tile', 'Owning project']),
    );

    final subtitle = texts.singleWhere((text) => text.data == 'Owning project');
    final label = texts.singleWhere((text) => text.data == 'A launcher tile');
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
    expect(subtitle.style!.fontSize, lessThan(label.style!.fontSize!));
  });

  testWidgets('long label and subtitle fit a 100x100 tile', (tester) async {
    await pumpTile(
      tester,
      entry.copyWith(
        label: 'A very long launcher action label that should be truncated',
        subtitle:
            'A very long owning project subtitle that should be truncated',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('long label and subtitle fit a three-column phone grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridView.count(
            crossAxisCount: 3,
            children: [
              LauncherTileWidget(
                entry: entry.copyWith(
                  label:
                      'A very long launcher action label that should be truncated',
                  subtitle:
                      'A very long owning project subtitle that should be truncated',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
