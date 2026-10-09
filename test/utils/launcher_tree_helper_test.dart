import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tiles/flutter_tiles.dart';

LauncherEntry _folder(String id, {String? parentId, String? label}) =>
    LauncherEntry(
      id: id,
      folderPath: '',
      label: label ?? id,
      action: LauncherEntry.folderAction,
      iconName: 'folder',
      backgroundColor: 0xFF000000,
      sortOrder: 0,
      createdAtMs: 0,
      parentId: parentId,
    );

LauncherEntry _tile(String id, {String? parentId, int color = 0xFF000000}) =>
    LauncherEntry(
      id: id,
      folderPath: '/f',
      label: id,
      action: 'openFolder',
      iconName: 'folder',
      backgroundColor: color,
      sortOrder: 0,
      createdAtMs: 0,
      parentId: parentId,
    );

void main() {
  // Tree: root → A → B → tile t; sibling folder C at root.
  final entries = [
    _folder('A'),
    _folder('B', parentId: 'A'),
    _tile('t', parentId: 'B'),
    _folder('C'),
  ];

  group('ancestors', () {
    test('returns chain from root down to the given folder', () {
      final chain = LauncherTreeHelper.ancestors(entries, 'B');
      expect(chain.map((e) => e.id), ['A', 'B']);
    });

    test('is empty for null (root level)', () {
      expect(LauncherTreeHelper.ancestors(entries, null), isEmpty);
    });

    test('terminates on cyclic corrupt data', () {
      final cyclic = [_folder('A', parentId: 'B'), _folder('B', parentId: 'A')];
      final chain = LauncherTreeHelper.ancestors(cyclic, 'A');
      expect(chain.length, lessThanOrEqualTo(2));
    });
  });

  group('ancestorLabelPath', () {
    test('joins ancestor labels with " / "', () {
      final withLabels = [
        _folder('A', label: 'Games'),
        _folder('B', parentId: 'A', label: 'Retro'),
      ];
      expect(
        LauncherTreeHelper.ancestorLabelPath(withLabels, 'B'),
        'Games / Retro',
      );
    });

    test('is null for root', () {
      expect(LauncherTreeHelper.ancestorLabelPath(entries, null), isNull);
    });
  });

  group('descendantIds', () {
    test('collects nested children, excluding the folder itself', () {
      expect(LauncherTreeHelper.descendantIds(entries, 'A'), {'B', 't'});
    });

    test('is empty for a leaf folder', () {
      expect(LauncherTreeHelper.descendantIds(entries, 'C'), isEmpty);
    });
  });

  group('childCount', () {
    test('counts only direct children, folders and tiles alike', () {
      expect(LauncherTreeHelper.childCount(entries, 'A'), 1);
      expect(LauncherTreeHelper.childCount(entries, 'B'), 1);
    });

    test('is zero for an empty folder', () {
      expect(LauncherTreeHelper.childCount(entries, 'C'), 0);
    });
  });

  group('wouldCreateCycle', () {
    test('null target (root) is always safe', () {
      expect(LauncherTreeHelper.wouldCreateCycle(entries, 'A', null), isFalse);
    });

    test('moving into itself is a cycle', () {
      expect(LauncherTreeHelper.wouldCreateCycle(entries, 'A', 'A'), isTrue);
    });

    test('moving into a descendant is a cycle', () {
      expect(LauncherTreeHelper.wouldCreateCycle(entries, 'A', 'B'), isTrue);
    });

    test('moving into an unrelated folder is safe', () {
      expect(LauncherTreeHelper.wouldCreateCycle(entries, 'A', 'C'), isFalse);
    });
  });

  group('sharedChildBackgroundColor', () {
    const red = 0xFFFF0000;
    const green = 0xFF00FF00;

    test('returns the shared color when all children of a folder match', () {
      final list = [
        _folder('F'),
        _tile('a', parentId: 'F', color: red),
        _tile('b', parentId: 'F', color: red),
      ];
      expect(LauncherTreeHelper.sharedChildBackgroundColor(list, 'F'), red);
    });

    test('returns null when two children of the same folder differ', () {
      final list = [
        _folder('F'),
        _tile('a', parentId: 'F', color: red),
        _tile('b', parentId: 'F', color: green),
      ];
      expect(LauncherTreeHelper.sharedChildBackgroundColor(list, 'F'), isNull);
    });

    test('returns the top-level color, ignoring entries nested in folders', () {
      final list = [
        _tile('a', color: red),
        _tile('b', color: red),
        _folder('F'),
        _tile('c', parentId: 'F', color: green),
      ];
      // The folder tile itself is at the top level with the default black.
      final topOnly = [
        _tile('a', color: red),
        _tile('b', color: red),
        _tile('c', parentId: 'F', color: green),
      ];
      expect(LauncherTreeHelper.sharedChildBackgroundColor(topOnly, null), red);
      expect(LauncherTreeHelper.sharedChildBackgroundColor(list, null), isNull);
    });

    test('returns null for an empty level', () {
      expect(
        LauncherTreeHelper.sharedChildBackgroundColor(entries, 'C'),
        isNull,
      );
      expect(LauncherTreeHelper.sharedChildBackgroundColor([], null), isNull);
    });

    test('returns the color when the level holds exactly one entry', () {
      final list = [_folder('F'), _tile('a', parentId: 'F', color: green)];
      expect(LauncherTreeHelper.sharedChildBackgroundColor(list, 'F'), green);
    });
  });
}
