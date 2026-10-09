import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  late LauncherStore testPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testPrefs = LauncherStore(prefs: prefs);
  });

  const entry1 = LauncherEntry(
    id: 'id_1',
    folderPath: '/storage/emulated/0/DCIM',
    label: 'Camera',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF2196F3,
    sortOrder: 0,
    createdAtMs: 1700000000000,
  );

  const entry2 = LauncherEntry(
    id: 'id_2',
    folderPath: '/storage/emulated/0/Pictures',
    label: 'Pictures',
    action: 'openFolder',
    iconName: 'image',
    backgroundColor: 0xFFFF5722,
    sortOrder: 1,
    createdAtMs: 1700000001000,
  );

  const entry3 = LauncherEntry(
    id: 'id_3',
    folderPath: '/storage/emulated/0/Music',
    label: 'Music',
    action: 'openFolder',
    iconName: 'music',
    backgroundColor: 0xFF4CAF50,
    sortOrder: 2,
    createdAtMs: 1700000002000,
  );

  group('LauncherStore - CRUD', () {
    test('getEntries returns empty list when no data', () {
      // Act
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries, isEmpty);
    });

    test('addEntry adds entry', () async {
      // Act
      await testPrefs.addEntry(entry1);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(1));
      expect(entries.first.id, equals('id_1'));
      expect(entries.first.label, equals('Camera'));
    });

    test('addEntry adds multiple entries', () async {
      // Act
      await testPrefs.addEntry(entry1);
      await testPrefs.addEntry(entry2);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(2));
    });

    test('removeEntry removes by id', () async {
      // Arrange
      await testPrefs.addEntry(entry1);
      await testPrefs.addEntry(entry2);

      // Act
      await testPrefs.removeEntry('id_1');
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(1));
      expect(entries.first.id, equals('id_2'));
    });

    test('removeEntry with non-existent id does nothing', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      await testPrefs.removeEntry('non_existent');
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(1));
    });

    test('updateEntry updates existing entry', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      final updated = entry1.copyWith(label: 'Updated Camera');
      await testPrefs.updateEntry(updated);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(1));
      expect(entries.first.label, equals('Updated Camera'));
    });

    test('updateEntry with non-existent id does nothing', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      const nonExistent = LauncherEntry(
        id: 'non_existent',
        folderPath: '/path',
        label: 'X',
        action: 'openFolder',
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 0,
      );
      await testPrefs.updateEntry(nonExistent);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(1));
      expect(entries.first.label, equals('Camera'));
    });

    test('setEntries replaces all entries', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      await testPrefs.setEntries([entry2, entry3]);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries.length, equals(2));
      expect(entries[0].id, equals('id_2'));
      expect(entries[1].id, equals('id_3'));
    });
  });

  group('LauncherStore - Raw JSON', () {
    test('getRaw returns null when no data', () {
      // Act
      final raw = testPrefs.getRaw();

      // Assert
      expect(raw, isNull);
    });

    test('getRaw returns valid JSON after add', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      final raw = testPrefs.getRaw();

      // Assert
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded.length, equals(1));
    });

    test('setRaw with null removes data', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      await testPrefs.setRaw(null);
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries, isEmpty);
    });

    test('setRaw with empty string removes data', () async {
      // Arrange
      await testPrefs.addEntry(entry1);

      // Act
      await testPrefs.setRaw('');
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries, isEmpty);
    });

    test('setRaw restores entries', () async {
      // Arrange
      await testPrefs.addEntry(entry1);
      await testPrefs.addEntry(entry2);
      final raw = testPrefs.getRaw();

      // Clear and restore
      await testPrefs.setRaw(null);
      await testPrefs.setRaw(raw);

      // Assert
      final entries = testPrefs.getEntries();
      expect(entries.length, equals(2));
    });
  });

  group('LauncherStore - Reorder', () {
    test('reorderEntries updates sortOrder', () async {
      // Arrange
      await testPrefs.addEntry(entry1);
      await testPrefs.addEntry(entry2);
      await testPrefs.addEntry(entry3);

      // Act - reverse order
      await testPrefs.reorderEntries([entry3, entry2, entry1]);
      final entries = testPrefs.getEntries();

      // Assert - sorted by new sortOrder
      expect(entries[0].id, equals('id_3'));
      expect(entries[0].sortOrder, equals(0));
      expect(entries[1].id, equals('id_2'));
      expect(entries[1].sortOrder, equals(1));
      expect(entries[2].id, equals('id_1'));
      expect(entries[2].sortOrder, equals(2));
    });
  });

  group('LauncherStore - Nesting integrity', () {
    LauncherEntry folder(String id, {String? parentId}) => LauncherEntry(
      id: id,
      folderPath: '',
      label: id,
      action: LauncherEntry.folderAction,
      iconName: 'folder',
      backgroundColor: 0xFF000000,
      sortOrder: 0,
      createdAtMs: 0,
      parentId: parentId,
    );

    test('valid deep nesting survives a read untouched', () async {
      // Arrange: root → A → B, tile inside B.
      await testPrefs.setEntries([
        folder('A'),
        folder('B', parentId: 'A'),
        entry1.copyWith(parentId: 'B'),
      ]);

      // Act
      final entries = testPrefs.getEntries();

      // Assert
      expect(
        {for (final e in entries) e.id: e.parentId},
        {'A': null, 'B': 'A', 'id_1': 'B'},
      );
    });

    test('cyclic folder chain is broken to the root on read', () async {
      // Arrange: corrupt import where A and B parent each other.
      await testPrefs.setEntries([
        folder('A', parentId: 'B'),
        folder('B', parentId: 'A'),
        entry1.copyWith(parentId: 'B'),
      ]);

      // Act
      final entries = testPrefs.getEntries();

      // Assert: cycle members re-rooted; the tile stays inside B, which is
      // reachable again after the repair.
      final byId = {for (final e in entries) e.id: e.parentId};
      expect(byId['A'], isNull);
      expect(byId['B'], isNull);
      expect(byId['id_1'], 'B');
    });

    test('self-parenting folder is re-rooted on read', () async {
      await testPrefs.setEntries([folder('A', parentId: 'A')]);

      final entries = testPrefs.getEntries();

      expect(entries.single.parentId, isNull);
    });
  });

  group('LauncherStore - Error Handling', () {
    test('getEntries returns empty for corrupt JSON', () async {
      // Arrange - set corrupt data directly
      final prefs = testPrefs.prefs;
      await prefs.setString('launcher_entries', 'not valid json');

      // Act
      final entries = testPrefs.getEntries();

      // Assert
      expect(entries, isEmpty);
    });
  });
}
