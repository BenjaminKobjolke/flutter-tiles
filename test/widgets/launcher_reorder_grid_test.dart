import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const folder = LauncherEntry(
    id: 'f',
    folderPath: '',
    label: 'Folder',
    action: LauncherEntry.folderAction,
    iconName: 'folder',
    backgroundColor: 0xFF333333,
    sortOrder: 0,
    createdAtMs: 0,
  );
  const first = LauncherEntry(
    id: 'a',
    folderPath: '',
    label: 'First',
    action: 'open',
    iconName: 'folder',
    backgroundColor: 0xFF333333,
    sortOrder: 1,
    createdAtMs: 0,
    parentId: 'f',
  );
  const second = LauncherEntry(
    id: 'b',
    folderPath: '',
    label: 'Second',
    action: 'open',
    iconName: 'folder',
    backgroundColor: 0xFF333333,
    sortOrder: 2,
    createdAtMs: 0,
    parentId: 'f',
  );

  testWidgets('renders open level in order and ejects a child', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LauncherStore(prefs: prefs);
    await store.setEntries([folder, first, second]);
    final cubit = LauncherCubit(store: store)
      ..loadEntries()
      ..openFolder('f');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: LauncherReorderGrid(
              state: cubit.state as LauncherLoaded,
              entries: [first, second],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('First')).dx,
      lessThan(tester.getTopLeft(find.text('Second')).dx),
    );
    expect(find.byTooltip('Move out of folder'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Move out of folder').first);
    await tester.pump();
    expect(store.getEntries().firstWhere((e) => e.id == 'a').parentId, isNull);
    await cubit.close();
  });

  testWidgets('top level has no eject button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = LauncherCubit(store: LauncherStore(prefs: prefs))
      ..loadEntries();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: LauncherReorderGrid(
              state: cubit.state as LauncherLoaded,
              entries: const [folder],
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Move out of folder'), findsNothing);
    await cubit.close();
  });

  testWidgets('dropping a tile center-to-center groups it in a folder', (
    tester,
  ) async {
    const dragged = LauncherEntry(
      id: 'dragged',
      folderPath: '',
      label: 'Dragged',
      action: 'open',
      iconName: 'folder',
      backgroundColor: 0xFF333333,
      sortOrder: 0,
      createdAtMs: 0,
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LauncherStore(prefs: prefs);
    await store.setEntries([folder, dragged]);
    final cubit = LauncherCubit(store: store)..loadEntries();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: LauncherReorderGrid(
              state: cubit.state as LauncherLoaded,
              entries: [folder, dragged],
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Dragged')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(
      tester.getCenter(find.text('Folder')),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      store.getEntries().firstWhere((entry) => entry.id == 'dragged').parentId,
      'f',
    );
    await cubit.close();
  });

  testWidgets('left and right pointer edges reorder to the matching side', (
    tester,
  ) async {
    for (final edge in ['left', 'right']) {
      final target = folder.copyWith(
        id: 'target',
        label: 'Target',
        sortOrder: 0,
      );
      final other = first.copyWith(id: 'other', label: 'Other', sortOrder: 1);
      final dragged = second.copyWith(
        id: 'dragged',
        label: 'Dragged',
        sortOrder: 2,
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LauncherStore(prefs: prefs);
      await store.setEntries([target, other, dragged]);
      final cubit = LauncherCubit(store: store)..loadEntries();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: LauncherReorderGrid(
                state: cubit.state as LauncherLoaded,
                entries: [target, other, dragged],
              ),
            ),
          ),
        ),
      );
      final targetRect = tester.getRect(
        find.ancestor(
          of: find.text('Target'),
          matching: find.byType(LauncherTileWidget),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Dragged')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(
        Offset(
          edge == 'left' ? targetRect.left + 1 : targetRect.right - 1,
          targetRect.center.dy,
        ),
        timeStamp: const Duration(milliseconds: 400),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();
      final ids = store.getEntries().map((entry) => entry.id).toList();
      expect(
        ids.take(2),
        edge == 'left' ? ['dragged', 'target'] : ['target', 'dragged'],
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    }
  });
}
