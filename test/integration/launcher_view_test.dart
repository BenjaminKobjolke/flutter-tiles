import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const camera = LauncherEntry(
    id: 'camera',
    folderPath: '',
    label: 'Camera',
    action: 'open',
    iconName: 'camera',
    backgroundColor: 0xFF333333,
    sortOrder: 0,
    createdAtMs: 0,
  );
  const albums = LauncherEntry(
    id: 'albums',
    folderPath: '',
    label: 'Albums',
    action: LauncherEntry.folderAction,
    iconName: 'folder',
    backgroundColor: 0xFF333333,
    sortOrder: 1,
    createdAtMs: 0,
    pinned: true,
  );

  late LauncherStore store;
  late LauncherCubit cubit;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LauncherStore(prefs: await SharedPreferences.getInstance());
    await store.setEntries([camera, albums]);
    cubit = LauncherCubit(store: store)..loadEntries();
  });
  tearDown(() => cubit.close());

  Future<void> showView(
    WidgetTester tester, {
    String query = '',
    ValueChanged<LauncherEntry>? onTap,
    ValueChanged<LauncherEntry>? onUpdated,
    ValueChanged<LauncherEntry>? onDeleted,
    VoidCallback? onBackgroundLongPress,
    VoidCallback? onExitReorder,
    ValueChanged<int>? onCount,
    LauncherEmptyStateBuilder? emptyStateBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: LauncherView(
              filterQuery: query,
              emptyStateBuilder: emptyStateBuilder,
              onTileTap: onTap,
              onTileUpdated: onUpdated,
              onTileDeleted: onDeleted,
              onBackgroundLongPress: onBackgroundLongPress,
              onExitReorder: onExitReorder,
              bottomBuilder: (context, count) {
                onCount?.call(count);
                return const Text('Bottom slot');
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> expectHostEmpty(
    WidgetTester tester,
    LauncherEmptyCase expected, {
    String query = '',
  }) async {
    final cases = <LauncherEmptyCase>[];
    await showView(
      tester,
      query: query,
      emptyStateBuilder: (context, emptyCase) {
        cases.add(emptyCase);
        return const Text('host empty');
      },
    );
    await tester.pump();
    expect(cases, contains(expected));
    expect(find.text('host empty'), findsOneWidget);
    expect(find.byType(LauncherEmptyState), findsNothing);
    expect(find.text('Bottom slot'), findsOneWidget);
  }

  testWidgets('host empty builder receives no tiles', (tester) async {
    await store.setEntries([]);
    cubit.loadEntries();
    await expectHostEmpty(tester, LauncherEmptyCase.noTiles);
  });

  testWidgets('host empty builder receives empty folder', (tester) async {
    cubit.openFolder('albums');
    await expectHostEmpty(tester, LauncherEmptyCase.emptyFolder);
  });

  testWidgets('host empty builder receives no matches', (tester) async {
    await expectHostEmpty(
      tester,
      LauncherEmptyCase.noMatches,
      query: 'missing',
    );
  });

  testWidgets('default empty states retain their icons and titles', (
    tester,
  ) async {
    await store.setEntries([]);
    cubit.loadEntries();
    await showView(tester);
    await tester.pump();
    expect(find.text('No tiles'), findsOneWidget);
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    await store.setEntries([camera, albums]);
    cubit.loadEntries();
    await tester.pump();
    cubit.openFolder('albums');
    await tester.pump();
    expect(find.text('Empty folder'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    cubit.closeFolder();
    await showView(tester, query: 'missing');
    await tester.pump();
    expect(find.text('No tiles'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('pinned sort, tap, filter, empty state and bottom slot', (
    tester,
  ) async {
    LauncherEntry? tapped;
    var count = -1;
    await showView(
      tester,
      onTap: (entry) => tapped = entry,
      onCount: (value) => count = value,
    );
    expect(
      tester.getTopLeft(find.text('Albums')).dx,
      lessThan(tester.getTopLeft(find.text('Camera')).dx),
    );
    await tester.tap(find.text('Camera'));
    expect(tapped?.id, 'camera');
    await showView(tester, query: 'Cam', onCount: (value) => count = value);
    expect(find.text('Albums'), findsNothing);
    expect(count, 1);
    await showView(tester, query: 'missing', onCount: (value) => count = value);
    expect(find.text('No tiles'), findsOneWidget);
    expect(find.text('Bottom slot'), findsOneWidget);
    expect(count, 0);
  });

  testWidgets('editing saves entry and notifies host', (tester) async {
    LauncherEntry? updated;
    await showView(tester, onUpdated: (entry) => updated = entry);
    await tester.longPress(find.text('Camera'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tile name'),
      'Videos',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Videos'), findsOneWidget);
    expect(
      store.getEntries().firstWhere((entry) => entry.id == 'camera').label,
      'Videos',
    );
    expect(updated?.label, 'Videos');
  });

  testWidgets('deleting removes entry and notifies host', (tester) async {
    LauncherEntry? deleted;
    await showView(tester, onDeleted: (entry) => deleted = entry);
    await tester.longPress(find.text('Camera'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Tile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.getEntries().any((entry) => entry.id == 'camera'), isFalse);
    expect(deleted?.id, 'camera');
  });

  testWidgets('background long press and reorder bypass filter', (
    tester,
  ) async {
    var background = 0;
    var exits = 0;
    await showView(tester, onBackgroundLongPress: () => background++);
    await tester.longPressAt(const Offset(700, 500));
    expect(background, 1);
    cubit.toggleReorderMode();
    await showView(tester, query: 'missing', onExitReorder: () => exits++);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    await tester.tap(find.text('Exit Reorder Mode'));
    expect(exits, 1);
  });
}
