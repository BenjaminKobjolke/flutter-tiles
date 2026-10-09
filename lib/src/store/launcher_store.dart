import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/launcher_entry.dart';

/// Persists launcher entries in SharedPreferences.
class LauncherStore {
  /// Creates a store backed by [prefs].
  LauncherStore({required this.prefs, this.key = defaultKey});

  /// Existing Media File Explorer storage key.
  static const String defaultKey = 'launcher_entries';

  /// Preferences backing this store.
  final SharedPreferences prefs;

  /// Key holding the JSON entry list.
  final String key;

  /// Get all persisted launcher entries, sorted by [sortOrder].
  List<LauncherEntry> getEntries() {
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final entries = jsonList
          .map((item) => LauncherEntry.fromMap(item as Map<String, dynamic>))
          .toList();
      _reRootOrphans(entries);
      entries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return entries;
    } catch (e) {
      return [];
    }
  }

  /// Re-roots entries whose [LauncherEntry.parentId] points at a missing or
  /// non-folder entry, or whose parent chain forms a cycle (e.g. A→B→A from a
  /// corrupt import), so no tile can ever become unreachable. Mutates
  /// [entries] in place. Runs on every read — kept O(n).
  void _reRootOrphans(List<LauncherEntry> entries) {
    final folderIds = {
      for (final e in entries)
        if (e.isFolder) e.id,
    };
    for (var i = 0; i < entries.length; i++) {
      final parent = entries[i].parentId;
      if (parent != null && !folderIds.contains(parent)) {
        entries[i] = entries[i].copyWith(clearParent: true);
      }
    }

    // Reachability pass: BFS from the root level; any entry never reached
    // sits on a cyclic parent chain and gets re-rooted.
    final childrenByParent = <String?, List<int>>{};
    for (var i = 0; i < entries.length; i++) {
      childrenByParent.putIfAbsent(entries[i].parentId, () => []).add(i);
    }
    final reached = <int>{};
    final queue = [...?childrenByParent[null]];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      if (!reached.add(i)) continue;
      queue.addAll(childrenByParent[entries[i].id] ?? const []);
    }
    // Re-rooting only folders suffices: once every folder is reachable, every
    // tile inside one is too.
    for (var i = 0; i < entries.length; i++) {
      if (!reached.contains(i) && entries[i].isFolder) {
        entries[i] = entries[i].copyWith(clearParent: true);
      }
    }
  }

  /// Get raw launcher entries JSON string (for backup/restore).
  String? getRaw() {
    return prefs.getString(key);
  }

  /// Set all launcher entries.
  Future<void> setEntries(List<LauncherEntry> entries) async {
    final jsonList = entries.map((e) => e.toMap()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Set raw launcher entries JSON string (for backup/restore).
  Future<void> setRaw(String? jsonString) async {
    if (jsonString == null || jsonString.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonString);
    }
  }

  /// Add a launcher entry.
  Future<void> addEntry(LauncherEntry entry) async {
    final entries = getEntries();
    entries.add(entry);
    await setEntries(entries);
  }

  /// Remove a launcher entry by [id].
  Future<void> removeEntry(String id) async {
    final entries = getEntries();
    entries.removeWhere((e) => e.id == id);
    await setEntries(entries);
  }

  /// Update an existing launcher entry (matched by [id]).
  Future<void> updateEntry(LauncherEntry updated) async {
    final entries = getEntries();
    final index = entries.indexWhere((e) => e.id == updated.id);
    if (index >= 0) {
      entries[index] = updated;
      await setEntries(entries);
    }
  }

  /// Reorder launcher entries by updating [sortOrder] based on list position.
  Future<void> reorderEntries(List<LauncherEntry> reordered) async {
    final updated = <LauncherEntry>[];
    for (var i = 0; i < reordered.length; i++) {
      updated.add(reordered[i].copyWith(sortOrder: i));
    }
    await setEntries(updated);
  }
}
