import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const raw =
      '[{"id":"tile","folderPath":"/one","label":"One","action":"openFolder","filePath":null,"iconName":"folder","backgroundColor":4278190080,"fontColor":4294967295,"iconColor":4294967295,"sortOrder":0,"createdAtMs":1},{"id":"special","folderPath":"","label":"Special","action":"openFile","filePath":"/file","iconName":"file","backgroundColor":4278190080,"fontColor":4294967295,"iconColor":4294967295,"sortOrder":1,"createdAtMs":2,"extras":{"key":"value"},"customIconBase64":"aGVsbG8=","returnToLauncherOnBack":false,"pinned":true},{"id":"folder","folderPath":"","label":"Folder","action":"launcherFolder","filePath":null,"iconName":"folder","backgroundColor":4278190080,"fontColor":4294967295,"iconColor":4294967295,"sortOrder":2,"createdAtMs":3},{"id":"child","folderPath":"","label":"Child","action":"openFolder","filePath":null,"iconName":"folder","backgroundColor":4278190080,"fontColor":4294967295,"iconColor":4294967295,"sortOrder":3,"createdAtMs":4,"parentId":"folder"}]';

  test('app JSON round-trips byte for byte', () async {
    SharedPreferences.setMockInitialValues({LauncherStore.defaultKey: raw});
    final store = LauncherStore(prefs: await SharedPreferences.getInstance());
    final entries = store.getEntries();
    expect(entries, hasLength(4));
    expect(entries[1].filePath, '/file');
    expect(entries[1].extras, {'key': 'value'});
    expect(entries[1].customIconBase64, 'aGVsbG8=');
    expect(entries[1].returnToLauncherOnBack, isFalse);
    expect(entries[1].pinned, isTrue);
    expect(entries[3].parentId, 'folder');
    await store.setEntries(entries);
    expect(store.getRaw(), raw);
  });

  test('legacy JSON gets model defaults', () async {
    SharedPreferences.setMockInitialValues({
      LauncherStore.defaultKey:
          '[{"id":"old","folderPath":"","label":"Old","action":"openFolder","iconName":"folder","backgroundColor":0,"sortOrder":0,"createdAtMs":1}]',
    });
    final entry = LauncherStore(
      prefs: await SharedPreferences.getInstance(),
    ).getEntries().single;
    expect(entry.fontColor, 0xFFFFFFFF);
    expect(entry.iconColor, 0xFFFFFFFF);
    expect(entry.extras, isEmpty);
    expect(entry.pinned, isFalse);
  });

  test('stores with distinct keys are isolated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = LauncherStore(prefs: prefs);
    final second = LauncherStore(prefs: prefs, key: 'another');
    await first.setRaw(raw);
    expect(second.getEntries(), isEmpty);
    expect(prefs.getString('launcher_entries'), raw);
  });
}
