import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

void main() {
  const testEntry = LauncherEntry(
    id: '1234567890',
    folderPath: '/storage/emulated/0/DCIM',
    label: 'Camera',
    action: 'de.xida.folder_gallery.OPEN_FOLDER',
    iconName: 'folder',
    backgroundColor: 0xFF2196F3,
    sortOrder: 0,
    createdAtMs: 1700000000000,
  );

  const testEntryWithFile = LauncherEntry(
    id: '9876543210',
    folderPath: '/storage/emulated/0/Pictures',
    label: 'Photo',
    action: 'de.xida.folder_gallery.OPEN_FILE',
    filePath: '/storage/emulated/0/Pictures/photo.jpg',
    iconName: 'image',
    backgroundColor: 0xFFFF5722,
    sortOrder: 1,
    createdAtMs: 1700000001000,
  );

  group('LauncherEntry - Serialization', () {
    test('toMap produces correct map', () {
      // Act
      final map = testEntry.toMap();

      // Assert
      expect(map['id'], equals('1234567890'));
      expect(map['folderPath'], equals('/storage/emulated/0/DCIM'));
      expect(map['label'], equals('Camera'));
      expect(map['action'], equals('de.xida.folder_gallery.OPEN_FOLDER'));
      expect(map['filePath'], isNull);
      expect(map['iconName'], equals('folder'));
      expect(map['backgroundColor'], equals(0xFF2196F3));
      expect(map['fontColor'], equals(0xFFFFFFFF));
      expect(map['iconColor'], equals(0xFFFFFFFF));
      expect(map['sortOrder'], equals(0));
      expect(map['createdAtMs'], equals(1700000000000));
    });

    test('toMap includes filePath when set', () {
      // Act
      final map = testEntryWithFile.toMap();

      // Assert
      expect(map['filePath'], equals('/storage/emulated/0/Pictures/photo.jpg'));
    });

    test('fromMap roundtrip without filePath', () {
      // Act
      final map = testEntry.toMap();
      final restored = LauncherEntry.fromMap(map);

      // Assert
      expect(restored.id, equals(testEntry.id));
      expect(restored.folderPath, equals(testEntry.folderPath));
      expect(restored.label, equals(testEntry.label));
      expect(restored.action, equals(testEntry.action));
      expect(restored.filePath, isNull);
      expect(restored.iconName, equals(testEntry.iconName));
      expect(restored.backgroundColor, equals(testEntry.backgroundColor));
      expect(restored.fontColor, equals(testEntry.fontColor));
      expect(restored.iconColor, equals(testEntry.iconColor));
      expect(restored.sortOrder, equals(testEntry.sortOrder));
      expect(restored.createdAtMs, equals(testEntry.createdAtMs));
    });

    test('fromMap roundtrip with filePath', () {
      // Act
      final map = testEntryWithFile.toMap();
      final restored = LauncherEntry.fromMap(map);

      // Assert
      expect(restored.id, equals(testEntryWithFile.id));
      expect(restored.filePath, equals(testEntryWithFile.filePath));
    });

    test('toJson produces valid JSON string', () {
      // Act
      final json = testEntry.toJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      // Assert
      expect(decoded['id'], equals('1234567890'));
      expect(decoded['label'], equals('Camera'));
    });

    test('fromJson roundtrip', () {
      // Act
      final json = testEntry.toJson();
      final restored = LauncherEntry.fromJson(json);

      // Assert
      expect(restored.id, equals(testEntry.id));
      expect(restored.folderPath, equals(testEntry.folderPath));
      expect(restored.label, equals(testEntry.label));
    });

    test('fromJson roundtrip with filePath', () {
      // Act
      final json = testEntryWithFile.toJson();
      final restored = LauncherEntry.fromJson(json);

      // Assert
      expect(restored.filePath, equals(testEntryWithFile.filePath));
    });
  });

  group('LauncherEntry - Equality', () {
    test('entries with same id are equal', () {
      // Arrange
      const entry1 = LauncherEntry(
        id: 'same_id',
        folderPath: '/path/a',
        label: 'Label A',
        action: 'actionA',
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 1000,
      );
      const entry2 = LauncherEntry(
        id: 'same_id',
        folderPath: '/path/b',
        label: 'Label B',
        action: 'actionB',
        iconName: 'camera',
        backgroundColor: 0xFFFFFFFF,
        sortOrder: 5,
        createdAtMs: 2000,
      );

      // Assert
      expect(entry1, equals(entry2));
    });

    test('entries with different id are not equal', () {
      // Arrange
      const entry1 = LauncherEntry(
        id: 'id_1',
        folderPath: '/path',
        label: 'Label',
        action: 'action',
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 1000,
      );
      const entry2 = LauncherEntry(
        id: 'id_2',
        folderPath: '/path',
        label: 'Label',
        action: 'action',
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 1000,
      );

      // Assert
      expect(entry1, isNot(equals(entry2)));
    });

    test('hashCode is based on id', () {
      // Assert
      expect(testEntry.hashCode, equals('1234567890'.hashCode));
      expect(testEntryWithFile.hashCode, equals('9876543210'.hashCode));
    });

    test('entries with same id have same hashCode', () {
      // Arrange
      const entry1 = LauncherEntry(
        id: 'shared',
        folderPath: '/a',
        label: 'A',
        action: 'x',
        iconName: 'folder',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 1,
      );
      const entry2 = LauncherEntry(
        id: 'shared',
        folderPath: '/b',
        label: 'B',
        action: 'y',
        iconName: 'camera',
        backgroundColor: 0xFFFFFFFF,
        sortOrder: 9,
        createdAtMs: 2,
      );

      // Assert
      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });

  group('LauncherEntry - copyWith', () {
    test('copyWith returns new instance with updated fields', () {
      // Act
      final updated = testEntry.copyWith(
        label: 'Updated',
        backgroundColor: 0xFFFF0000,
        sortOrder: 5,
      );

      // Assert
      expect(updated.id, equals(testEntry.id));
      expect(updated.label, equals('Updated'));
      expect(updated.backgroundColor, equals(0xFFFF0000));
      expect(updated.sortOrder, equals(5));
      expect(updated.folderPath, equals(testEntry.folderPath));
    });

    test('copyWith with no arguments returns equivalent entry', () {
      // Act
      final copy = testEntry.copyWith();

      // Assert
      expect(copy.id, equals(testEntry.id));
      expect(copy.label, equals(testEntry.label));
      expect(copy.folderPath, equals(testEntry.folderPath));
    });

    test('copyWith updates fontColor and iconColor', () {
      // Act
      final updated = testEntry.copyWith(
        fontColor: 0xFFFF0000,
        iconColor: 0xFF00FF00,
      );

      // Assert
      expect(updated.fontColor, equals(0xFFFF0000));
      expect(updated.iconColor, equals(0xFF00FF00));
      expect(updated.backgroundColor, equals(testEntry.backgroundColor));
    });
  });

  group('LauncherEntry - Backward Compatibility', () {
    test('fromMap without fontColor/iconColor defaults to white', () {
      // Arrange — old format without the new color fields
      final oldMap = {
        'id': '1234567890',
        'folderPath': '/storage/emulated/0/DCIM',
        'label': 'Camera',
        'action': 'de.xida.folder_gallery.OPEN_FOLDER',
        'iconName': 'folder',
        'backgroundColor': 0xFF2196F3,
        'sortOrder': 0,
        'createdAtMs': 1700000000000,
      };

      // Act
      final restored = LauncherEntry.fromMap(oldMap);

      // Assert
      expect(restored.fontColor, equals(0xFFFFFFFF));
      expect(restored.iconColor, equals(0xFFFFFFFF));
      expect(restored.backgroundColor, equals(0xFF2196F3));
    });

    test('toMap omits customIconBase64 when null', () {
      final map = testEntry.toMap();
      expect(map.containsKey('customIconBase64'), isFalse);
    });

    test('toMap/fromMap roundtrip preserves customIconBase64', () {
      const encoded = 'iVBORw0KGgoAAAANSUhEUgAA';
      const entry = LauncherEntry(
        id: 'app-1',
        folderPath: '',
        label: 'Maps',
        action: 'de.xida.folder_gallery.LAUNCH_APP',
        iconName: 'mobileScreen',
        backgroundColor: 0xFF000000,
        sortOrder: 0,
        createdAtMs: 1700000000000,
        customIconBase64: encoded,
      );

      final map = entry.toMap();
      expect(map['customIconBase64'], equals(encoded));

      final restored = LauncherEntry.fromMap(map);
      expect(restored.customIconBase64, equals(encoded));
    });

    test('fromMap defaults customIconBase64 to null when missing', () {
      final oldMap = {
        'id': 'x',
        'folderPath': '',
        'label': 'L',
        'action': 'a',
        'iconName': 'folder',
        'backgroundColor': 0xFF000000,
        'sortOrder': 0,
        'createdAtMs': 0,
      };
      final restored = LauncherEntry.fromMap(oldMap);
      expect(restored.customIconBase64, isNull);
    });

    test('returnToLauncherOnBack defaults to true', () {
      expect(testEntry.returnToLauncherOnBack, isTrue);
    });

    test('toMap omits returnToLauncherOnBack when true (default)', () {
      final map = testEntry.toMap();
      expect(map.containsKey('returnToLauncherOnBack'), isFalse);
    });

    test('toMap persists returnToLauncherOnBack when false', () {
      final map = testEntry.copyWith(returnToLauncherOnBack: false).toMap();
      expect(map['returnToLauncherOnBack'], isFalse);
    });

    test('fromMap without returnToLauncherOnBack defaults to true', () {
      final oldMap = {
        'id': 'x',
        'folderPath': '',
        'label': 'L',
        'action': 'a',
        'iconName': 'folder',
        'backgroundColor': 0xFF000000,
        'sortOrder': 0,
        'createdAtMs': 0,
      };
      expect(LauncherEntry.fromMap(oldMap).returnToLauncherOnBack, isTrue);
    });

    test('returnToLauncherOnBack=false round-trips through JSON', () {
      final entry = testEntry.copyWith(returnToLauncherOnBack: false);
      final restored = LauncherEntry.fromJson(entry.toJson());
      expect(restored.returnToLauncherOnBack, isFalse);
    });

    test('fromMap with custom colors preserves them', () {
      // Arrange
      final map = {
        'id': '1234567890',
        'folderPath': '/storage/emulated/0/DCIM',
        'label': 'Camera',
        'action': 'de.xida.folder_gallery.OPEN_FOLDER',
        'iconName': 'folder',
        'backgroundColor': 0xFF2196F3,
        'fontColor': 0xFFFF0000,
        'iconColor': 0xFF00FF00,
        'sortOrder': 0,
        'createdAtMs': 1700000000000,
      };

      // Act
      final restored = LauncherEntry.fromMap(map);

      // Assert
      expect(restored.fontColor, equals(0xFFFF0000));
      expect(restored.iconColor, equals(0xFF00FF00));
    });
  });

  group('LauncherEntry - Folders (parentId)', () {
    test('parentId defaults to null (top level)', () {
      expect(testEntry.parentId, isNull);
    });

    test('toMap omits parentId when null', () {
      expect(testEntry.toMap().containsKey('parentId'), isFalse);
    });

    test('toMap/fromMap roundtrip preserves parentId', () {
      final child = testEntry.copyWith(parentId: 'folder-1');
      final map = child.toMap();
      expect(map['parentId'], equals('folder-1'));
      expect(LauncherEntry.fromMap(map).parentId, equals('folder-1'));
    });

    test('fromMap without parentId defaults to null', () {
      final oldMap = {
        'id': 'x',
        'folderPath': '',
        'label': 'L',
        'action': 'a',
        'iconName': 'folder',
        'backgroundColor': 0xFF000000,
        'sortOrder': 0,
        'createdAtMs': 0,
      };
      expect(LauncherEntry.fromMap(oldMap).parentId, isNull);
    });

    test('copyWith(clearParent: true) nulls out parentId', () {
      final child = testEntry.copyWith(parentId: 'folder-1');
      final rooted = child.copyWith(clearParent: true);
      expect(rooted.parentId, isNull);
    });

    test('isFolder reflects the folder action constant', () {
      final folder = testEntry.copyWith(action: LauncherEntry.folderAction);
      expect(folder.isFolder, isTrue);
      expect(testEntry.isFolder, isFalse);
    });
  });

  group('LauncherEntry - Pinning (pinned)', () {
    test('pinned defaults to false', () {
      expect(testEntry.pinned, isFalse);
    });

    test('toMap omits pinned when false (default)', () {
      expect(testEntry.toMap().containsKey('pinned'), isFalse);
    });

    test('toMap persists pinned when true', () {
      expect(testEntry.copyWith(pinned: true).toMap()['pinned'], isTrue);
    });

    test('fromMap without pinned defaults to false', () {
      final oldMap = {
        'id': 'x',
        'folderPath': '',
        'label': 'L',
        'action': 'a',
        'iconName': 'folder',
        'backgroundColor': 0xFF000000,
        'sortOrder': 0,
        'createdAtMs': 0,
      };
      expect(LauncherEntry.fromMap(oldMap).pinned, isFalse);
    });

    test('pinned=true round-trips through JSON', () {
      final restored = LauncherEntry.fromJson(
        testEntry.copyWith(pinned: true).toJson(),
      );
      expect(restored.pinned, isTrue);
    });
  });

  group('LauncherEntry - Webpage (url in extras)', () {
    const webpageEntry = LauncherEntry(
      id: 'web-1',
      folderPath: '',
      label: 'Example',
      action: 'de.xida.folder_gallery.OPEN_WEBPAGE',
      iconName: 'globe',
      backgroundColor: 0xFF1E1E1E,
      sortOrder: 0,
      createdAtMs: 1700000000000,
      extras: {'url': 'https://example.com'},
    );

    test('toMap/fromMap roundtrip preserves the url', () {
      final restored = LauncherEntry.fromMap(webpageEntry.toMap());
      expect(restored.action, equals('de.xida.folder_gallery.OPEN_WEBPAGE'));
      expect(restored.extras['url'], equals('https://example.com'));
    });

    test('toJson/fromJson roundtrip preserves the url', () {
      final restored = LauncherEntry.fromJson(webpageEntry.toJson());
      expect(restored.extras['url'], equals('https://example.com'));
    });
  });
}
