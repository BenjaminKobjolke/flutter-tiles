import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  final entries = [
    const LauncherEntry(
      id: '1',
      folderPath: '',
      label: 'Blue Camera',
      action: 'open',
      iconName: 'camera',
      backgroundColor: 0,
      sortOrder: 0,
      createdAtMs: 0,
    ),
    const LauncherEntry(
      id: '2',
      folderPath: '',
      label: 'Red Folder',
      action: 'open',
      iconName: 'folder',
      backgroundColor: 0,
      sortOrder: 1,
      createdAtMs: 0,
    ),
  ];

  test('empty query returns all entries', () {
    expect(LauncherFilter.apply(entries, '  '), same(entries));
  });

  test('all terms match regardless of case', () {
    expect(LauncherFilter.apply(entries, 'CAM blue').map((e) => e.id), ['1']);
  });

  test('no match returns an empty list', () {
    expect(LauncherFilter.apply(entries, 'missing'), isEmpty);
  });
}
