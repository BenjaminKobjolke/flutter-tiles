import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  const entry = LauncherEntry(
    id: '1',
    folderPath: '/old',
    filePath: '/file',
    label: 'Old',
    action: 'openFolder',
    iconName: 'folder',
    backgroundColor: 0xFF111111,
    sortOrder: 4,
    createdAtMs: 7,
    extras: {'x': 'y'},
    customIconBase64: 'bitmap',
    parentId: 'old',
  );

  LauncherTileEditResult result({
    bool clearCustomIcon = false,
    LauncherFolderPick? move,
    String? folderPath,
    String? filePath,
    Map<String, String>? extras,
  }) => LauncherTileEditResult(
    label: 'New',
    iconName: 'camera',
    iconData: Icons.camera,
    backgroundColor: const Color(0xFF222222),
    fontColor: Colors.red,
    iconColor: Colors.blue,
    pinned: true,
    clearCustomIcon: clearCustomIcon,
    move: move,
    folderPath: folderPath,
    filePath: filePath,
    extras: extras,
  );

  test('updates generic fields while preserving identity and settings', () {
    final updated = result().applyTo(entry);
    expect(updated.label, 'New');
    expect(updated.iconName, 'camera');
    expect(updated.backgroundColor, 0xFF222222);
    expect(updated.pinned, true);
    expect(updated.id, '1');
    expect(updated.sortOrder, 4);
    expect(updated.folderPath, '/old');
    expect(updated.filePath, '/file');
    expect(updated.extras, {'x': 'y'});
    expect(updated.customIconBase64, 'bitmap');
  });

  test('clears custom bitmap and applies settings draft', () {
    final updated = result(
      clearCustomIcon: true,
      folderPath: '/new',
      filePath: '/new-file',
      extras: {'a': 'b'},
    ).applyTo(entry);
    expect(updated.customIconBase64, isNull);
    expect(updated.folderPath, '/new');
    expect(updated.filePath, '/new-file');
    expect(updated.extras, {'a': 'b'});
  });

  test('staged move enters a folder or returns to root', () {
    final moved = result(
      move: const LauncherFolderPick(parentId: 'target', label: 'Target'),
    ).applyTo(entry);
    expect(moved.parentId, 'target');
    final root = result(
      move: const LauncherFolderPick(parentId: null, label: 'Root'),
    ).applyTo(entry);
    expect(root.parentId, isNull);
  });
}
