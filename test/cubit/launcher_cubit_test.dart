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

  const entry3 = LauncherEntry(
    id: 'id_3',
    folderPath: '/Music',
    label: 'Music',
    action: 'openFolder',
    iconName: 'music',
    backgroundColor: 0xFF4CAF50,
    sortOrder: 2,
    createdAtMs: 1700000002000,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LauncherStore(prefs: await SharedPreferences.getInstance());
    cubit = LauncherCubit(store: store);
  });

  tearDown(() {
    cubit.close();
  });

  group('LauncherCubit - Initial State', () {
    test('initial state is LauncherInitial', () {
      expect(cubit.state, isA<LauncherInitial>());
    });
  });

  group('LauncherCubit - loadEntries', () {
    test('emits LauncherLoaded with empty entries', () {
      // Act
      cubit.loadEntries();

      // Assert
      expect(cubit.state, isA<LauncherLoaded>());
      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.allEntries, isEmpty);
      expect(loaded.entries, isEmpty);
    });

    test('emits LauncherLoaded with existing entries', () async {
      // Arrange
      await store.addEntry(entry1);
      await store.addEntry(entry2);

      // Act
      cubit.loadEntries();

      // Assert
      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.allEntries.length, equals(2));
    });
  });

  group('LauncherCubit - addEntry', () {
    test('adds entry and updates state', () async {
      // Arrange
      cubit.loadEntries();

      // Act
      await cubit.addEntry(entry1);

      // Assert
      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.allEntries.length, equals(1));
      expect(loaded.allEntries.first.id, equals('id_1'));
    });

    test('does nothing when not in LauncherLoaded state', () async {
      // Act - cubit is in LauncherInitial state
      await cubit.reorder(0, 1);

      // Assert
      expect(cubit.state, isA<LauncherInitial>());
    });
  });

  group('LauncherCubit - toggleReorderMode', () {
    test('toggles reorder mode on', () {
      // Arrange
      cubit.loadEntries();

      // Act
      cubit.toggleReorderMode();

      // Assert
      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.isReorderMode, isTrue);
    });

    test('toggles reorder mode off', () {
      // Arrange
      cubit.loadEntries();
      cubit.toggleReorderMode(); // on

      // Act
      cubit.toggleReorderMode(); // off

      // Assert
      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.isReorderMode, isFalse);
    });

    test('does nothing when not in LauncherLoaded state', () {
      // Act
      cubit.toggleReorderMode();

      // Assert
      expect(cubit.state, isA<LauncherInitial>());
    });
  });

  group('LauncherCubit - folders', () {
    test('createFolderFrom nests both tiles and adds a folder', () async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.addEntry(entry3);

      await cubit.createFolderFrom('id_1', 'id_2', 'Work');

      final loaded = cubit.state as LauncherLoaded;
      final folder = loaded.allEntries.firstWhere((e) => e.isFolder);
      expect(folder.label, equals('Work'));
      // The two grouped tiles now point at the new folder.
      final byId = {for (final e in loaded.allEntries) e.id: e};
      expect(byId['id_1']!.parentId, equals(folder.id));
      expect(byId['id_2']!.parentId, equals(folder.id));
      // The untouched tile stays at the top level.
      expect(byId['id_3']!.parentId, isNull);
      // Top level shows the folder + the ungrouped tile, not the members.
      expect(loaded.entries.map((e) => e.id), containsAll([folder.id, 'id_3']));
      expect(loaded.entries.map((e) => e.id), isNot(contains('id_1')));
    });

    test('openFolder/closeFolder switches the visible level', () async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.createFolderFrom('id_1', 'id_2', 'Work');
      final folderId = (cubit.state as LauncherLoaded).allEntries
          .firstWhere((e) => e.isFolder)
          .id;

      cubit.openFolder(folderId);
      var loaded = cubit.state as LauncherLoaded;
      expect(loaded.openFolderId, equals(folderId));
      expect(loaded.entries.map((e) => e.id), containsAll(['id_1', 'id_2']));

      cubit.closeFolder();
      loaded = cubit.state as LauncherLoaded;
      expect(loaded.openFolderId, isNull);
      expect(loaded.entries.map((e) => e.id), contains(folderId));
    });

    test('moveIntoFolder nests an existing tile', () async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.addEntry(entry3);
      await cubit.createFolderFrom('id_1', 'id_2', 'Work');
      final folderId = (cubit.state as LauncherLoaded).allEntries
          .firstWhere((e) => e.isFolder)
          .id;

      await cubit.moveIntoFolder('id_3', folderId);

      final byId = {
        for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
      };
      expect(byId['id_3']!.parentId, equals(folderId));
    });

    test(
      'moveToParent ejects a tile from a root folder to the top level',
      () async {
        cubit.loadEntries();
        await cubit.addEntry(entry1);
        await cubit.addEntry(entry2);
        await cubit.createFolderFrom('id_1', 'id_2', 'Work');

        await cubit.moveToParent('id_1');

        final byId = {
          for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
        };
        expect(byId['id_1']!.parentId, isNull);
      },
    );

    test('deleting a folder re-roots its children', () async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.createFolderFrom('id_1', 'id_2', 'Work');
      final folderId = (cubit.state as LauncherLoaded).allEntries
          .firstWhere((e) => e.isFolder)
          .id;

      await cubit.removeEntry(folderId);

      final loaded = cubit.state as LauncherLoaded;
      expect(loaded.allEntries.any((e) => e.id == folderId), isFalse);
      final byId = {for (final e in loaded.allEntries) e.id: e};
      expect(byId['id_1']!.parentId, isNull);
      expect(byId['id_2']!.parentId, isNull);
    });

    test('reorder only touches siblings at the current level', () async {
      cubit.loadEntries();
      await cubit.addEntry(entry1);
      await cubit.addEntry(entry2);
      await cubit.addEntry(entry3);
      // Group entry1 + entry2 into a folder, leaving [folder, entry3] on top.
      await cubit.createFolderFrom('id_1', 'id_2', 'Work');

      final before = (cubit.state as LauncherLoaded).entries
          .map((e) => e.id)
          .toList();
      expect(before.length, equals(2)); // folder + entry3
      await cubit.reorder(before.length - 1, 0); // move last to front

      final after = (cubit.state as LauncherLoaded).entries
          .map((e) => e.id)
          .toList();
      expect(after.first, equals(before.last));
      // The nested tiles are untouched and still hidden from the top level.
      expect(after, isNot(contains('id_1')));
      expect(after, isNot(contains('id_2')));
    });
  });

  group('LauncherCubit - nested folders', () {
    const folderA = LauncherEntry(
      id: 'folder_a',
      folderPath: '',
      label: 'A',
      action: LauncherEntry.folderAction,
      iconName: 'folder',
      backgroundColor: 0xFF000000,
      sortOrder: 3,
      createdAtMs: 0,
    );

    const folderB = LauncherEntry(
      id: 'folder_b',
      folderPath: '',
      label: 'B',
      action: LauncherEntry.folderAction,
      iconName: 'folder',
      backgroundColor: 0xFF000000,
      sortOrder: 4,
      createdAtMs: 0,
      parentId: 'folder_a',
    );

    Future<void> seedTree() async {
      cubit.loadEntries();
      await cubit.addEntry(folderA);
      await cubit.addEntry(folderB);
      await cubit.addEntry(entry1.copyWith(parentId: 'folder_b'));
    }

    test('closeFolder climbs one level at a time', () async {
      await seedTree();

      cubit.openFolder('folder_a');
      cubit.openFolder('folder_b');

      cubit.closeFolder();
      expect((cubit.state as LauncherLoaded).openFolderId, 'folder_a');

      cubit.closeFolder();
      expect((cubit.state as LauncherLoaded).openFolderId, isNull);
    });

    test(
      'moveToParent from a nested folder lands in the parent, not root',
      () async {
        await seedTree();

        await cubit.moveToParent('id_1');

        final byId = {
          for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
        };
        expect(byId['id_1']!.parentId, 'folder_a');
      },
    );

    test(
      'deleting a nested folder re-parents children to the grandparent',
      () async {
        await seedTree();

        await cubit.removeEntry('folder_b');

        final byId = {
          for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
        };
        expect(byId['id_1']!.parentId, 'folder_a');
      },
    );

    test(
      'createFolderFrom inside an open folder creates a nested folder',
      () async {
        await seedTree();
        await cubit.addEntry(entry2.copyWith(parentId: 'folder_b'));
        cubit.openFolder('folder_a');
        cubit.openFolder('folder_b');

        await cubit.createFolderFrom('id_1', 'id_2', 'Sub');

        final loaded = cubit.state as LauncherLoaded;
        final sub = loaded.allEntries.firstWhere((e) => e.label == 'Sub');
        expect(sub.parentId, 'folder_b');
        final byId = {for (final e in loaded.allEntries) e.id: e};
        expect(byId['id_1']!.parentId, sub.id);
        expect(byId['id_2']!.parentId, sub.id);
      },
    );

    test(
      'moveIntoFolder rejects moving a folder into its own descendant',
      () async {
        await seedTree();

        await cubit.moveIntoFolder('folder_a', 'folder_b');

        final byId = {
          for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
        };
        expect(byId['folder_a']!.parentId, isNull);
      },
    );

    test('moveIntoFolder nests a folder into an unrelated folder', () async {
      await seedTree();
      await cubit.addEntry(entry2); // unrelated top-level tile
      await cubit.createFolderFrom('id_2', 'id_2', 'C');
      final folderC = (cubit.state as LauncherLoaded).allEntries.firstWhere(
        (e) => e.label == 'C',
      );

      await cubit.moveIntoFolder(folderC.id, 'folder_b');

      final byId = {
        for (final e in (cubit.state as LauncherLoaded).allEntries) e.id: e,
      };
      expect(byId[folderC.id]!.parentId, 'folder_b');
    });
  });
}
