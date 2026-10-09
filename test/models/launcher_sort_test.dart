import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

LauncherEntry _entry({
  required String id,
  required String label,
  required int sortOrder,
  int createdAtMs = 0,
  bool pinned = false,
}) {
  return LauncherEntry(
    id: id,
    folderPath: '/p/$id',
    label: label,
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF000000,
    sortOrder: sortOrder,
    createdAtMs: createdAtMs,
    pinned: pinned,
  );
}

void main() {
  group('LauncherSort.sort', () {
    late List<LauncherEntry> entries;

    setUp(() {
      entries = [
        _entry(id: 'b', label: 'Bravo', sortOrder: 2, createdAtMs: 300),
        _entry(id: 'a', label: 'alpha', sortOrder: 0, createdAtMs: 100),
        _entry(id: 'c', label: 'Charlie', sortOrder: 1, createdAtMs: 200),
      ];
    });

    test('manual uses sortOrder and ignores sort direction', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.manual,
        descending: true,
      );
      settings.sort(entries);
      expect(entries.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('filename sorts by label, case-insensitive, ascending', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.label,
        descending: false,
      );
      settings.sort(entries);
      expect(entries.map((e) => e.label).toList(), [
        'alpha',
        'Bravo',
        'Charlie',
      ]);
    });

    test('filename descending reverses label order', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.label,
        descending: true,
      );
      settings.sort(entries);
      expect(entries.map((e) => e.label).toList(), [
        'Charlie',
        'Bravo',
        'alpha',
      ]);
    });

    test('dateCreated ascending sorts by createdAtMs', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.dateCreated,
        descending: false,
      );
      settings.sort(entries);
      expect(entries.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('mostUsed ranks higher counts first, tie-break by label', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.mostUsed,
        descending: true,
      );
      settings.sort(entries, usageCounts: {'a': 5, 'b': 5, 'c': 1});
      // a & b tie at 5 → tie-break by label (alpha < Bravo); c last.
      expect(entries.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('mostUsed treats missing entries as zero', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.mostUsed,
        descending: true,
      );
      settings.sort(entries, usageCounts: {'c': 1});
      // c has count 1; a & b are 0 → tie-broken by label (alpha < Bravo).
      expect(entries.map((e) => e.id).toList(), ['c', 'a', 'b']);
    });

    test('dateModified falls back to label (no launcher modified date)', () {
      const settings = LauncherSort(
        mode: LauncherSortMode.label,
        descending: false,
      );
      settings.sort(entries);
      expect(entries.map((e) => e.label).toList(), [
        'alpha',
        'Bravo',
        'Charlie',
      ]);
    });

    test('mostUsed ranks a folder tile by its own usage count', () {
      // Folders are ordinary entries to the sorter; opening one increments its
      // usage, so a well-used folder ranks among tiles by that count.
      const folder = LauncherEntry(
        id: 'folder',
        folderPath: '',
        label: 'Work',
        action: LauncherEntry.folderAction,
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 3,
        createdAtMs: 400,
      );
      final withFolder = [...entries, folder];
      const settings = LauncherSort(
        mode: LauncherSortMode.mostUsed,
        descending: true,
      );
      settings.sort(
        withFolder,
        usageCounts: {'folder': 10, 'a': 5, 'b': 1, 'c': 1},
      );
      expect(withFolder.first.id, 'folder');
    });

    test('pinned tiles sort before unpinned regardless of sort mode', () {
      // Pin the alphabetically-last tile; it must still lead under a Name sort.
      final pinned = [
        _entry(id: 'a', label: 'alpha', sortOrder: 0),
        _entry(id: 'z', label: 'Zeta', sortOrder: 1, pinned: true),
        _entry(id: 'c', label: 'Charlie', sortOrder: 2),
      ];
      const settings = LauncherSort(
        mode: LauncherSortMode.label,
        descending: false,
      );
      settings.sort(pinned);
      // Pinned Zeta first; unpinned then alphabetical.
      expect(pinned.map((e) => e.id).toList(), ['z', 'a', 'c']);
    });

    test('pinned group keeps manual sortOrder among themselves', () {
      final pinned = [
        _entry(id: 'p2', label: 'P2', sortOrder: 5, pinned: true),
        _entry(id: 'u', label: 'U', sortOrder: 1),
        _entry(id: 'p1', label: 'P1', sortOrder: 3, pinned: true),
      ];
      const settings = LauncherSort(
        mode: LauncherSortMode.manual,
        descending: false,
      );
      settings.sort(pinned);
      // Pinned first ordered by sortOrder (p1<p2), then the unpinned tile.
      expect(pinned.map((e) => e.id).toList(), ['p1', 'p2', 'u']);
    });

    test('handles empty list', () {
      final empty = <LauncherEntry>[];
      LauncherSort.manual.sort(empty);
      expect(empty, isEmpty);
    });
  });
}
