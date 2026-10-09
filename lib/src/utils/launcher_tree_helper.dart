import '../models/launcher_entry.dart';

/// Pure tree operations over the flat launcher entry list whose hierarchy is
/// encoded by [LauncherEntry.parentId] (a folder's [LauncherEntry.id] is its
/// key).
///
/// Mirrors `FavoriteTreeHelper` (which is keyed by `Favorite.path`) so the
/// breadcrumb title, folder picker, and move cycle-guard all share the same
/// traversal.
class LauncherTreeHelper {
  const LauncherTreeHelper._();

  /// The ancestor folders of [folderId], from the root down to [folderId]
  /// itself, walking [LauncherEntry.parentId] upwards. Empty when [folderId]
  /// is `null` (root). Used for the breadcrumb title and picker labels.
  static List<LauncherEntry> ancestors(
    List<LauncherEntry> entries,
    String? folderId,
  ) {
    final chain = <LauncherEntry>[];
    final byId = {for (final e in entries) e.id: e};
    var current = folderId;
    // Guard against cycles from corrupt data with a visited set.
    final visited = <String>{};
    while (current != null && visited.add(current)) {
      final folder = byId[current];
      if (folder == null) break;
      chain.insert(0, folder);
      current = folder.parentId;
    }
    return chain;
  }

  /// The labels of [folderId]'s ancestor chain joined with " / "
  /// (e.g. "Games / Retro"), or `null` when [folderId] is `null` (root).
  static String? ancestorLabelPath(
    List<LauncherEntry> entries,
    String? folderId,
  ) {
    final chain = ancestors(entries, folderId);
    return chain.isEmpty ? null : chain.map((e) => e.label).join(' / ');
  }

  /// Number of entries directly inside the folder [folderId].
  static int childCount(List<LauncherEntry> entries, String folderId) =>
      entries.where((e) => e.parentId == folderId).length;

  /// The ARGB32 background color shared by every entry directly inside
  /// [parentId] (`null` = top level), or `null` when that level is empty or its
  /// entries disagree.
  ///
  /// Used to seed a new tile with the level's color so it matches its siblings.
  static int? sharedChildBackgroundColor(
    List<LauncherEntry> entries,
    String? parentId,
  ) {
    int? shared;
    for (final e in entries) {
      if (e.parentId != parentId) continue;
      if (shared == null) {
        shared = e.backgroundColor;
      } else if (shared != e.backgroundColor) {
        return null;
      }
    }
    return shared;
  }

  /// All descendant ids of the folder [folderId] (children, their
  /// children, …). Excludes [folderId] itself.
  static Set<String> descendantIds(
    List<LauncherEntry> entries,
    String folderId,
  ) {
    final result = <String>{};
    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final parent = queue.removeLast();
      for (final e in entries) {
        if (e.parentId == parent && result.add(e.id)) {
          queue.add(e.id);
        }
      }
    }
    return result;
  }

  /// Whether moving the entry [sourceId] into [targetParentId] would create a
  /// cycle: rejected when the target is the source itself or any of its
  /// descendants. A `null` target (root) is always safe.
  static bool wouldCreateCycle(
    List<LauncherEntry> entries,
    String sourceId,
    String? targetParentId,
  ) {
    if (targetParentId == null) return false;
    if (targetParentId == sourceId) return true;
    return descendantIds(entries, sourceId).contains(targetParentId);
  }
}
