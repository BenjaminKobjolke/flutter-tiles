import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  late LauncherCubit cubit;
  late LauncherStore store;

  const entry1 = LauncherEntry(
    id: 'id_1',
    folderPath: '/DCIM',
    label: 'Camera',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF2196F3,
    sortOrder: 0,
    createdAtMs: 1700000000000,
  );

  const entry2 = LauncherEntry(
    id: 'id_2',
    folderPath: '/Pictures',
    label: 'Pictures',
    action: 'openFolder',
    iconName: 'image',
    backgroundColor: 0xFFFF5722,
    sortOrder: 1,
    createdAtMs: 1700000001000,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LauncherStore(prefs: await SharedPreferences.getInstance());
    cubit = LauncherCubit(store: store);
  });

  tearDown(() {
    cubit.close();
  });

  group('LauncherCubit - reloadKeepingState', () {
    /// Builds a launcher with one folder holding both tiles and opens it.
    Future<String> openWorkFolder() async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.createFolderFrom('id_1', 'id_2', 'Work');
      final folderId = (cubit.state as LauncherLoaded).allEntries
          .firstWhere((e) => e.isFolder)
          .id;
      cubit.openFolder(folderId);
      return folderId;
    }

    test('keeps the open folder level', () async {
      final folderId = await openWorkFolder();

      // Returning to the launcher tab refreshes entries; the open sub-grid
      // must survive it.
      cubit.reloadKeepingState();

      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.openFolderId, equals(folderId));
      expect(loaded.entries.map((e) => e.id), containsAll(['id_1', 'id_2']));
    });

    test('loadEntries still resets to the top level', () async {
      await openWorkFolder();

      cubit.loadEntries();

      expect((cubit.state as LauncherLoaded).openFolderId, isNull);
    });
  });
}
