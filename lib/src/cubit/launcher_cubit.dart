import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/launcher_entry.dart';
import '../models/launcher_sort.dart';
import '../store/launcher_store.dart';
import '../utils/launcher_tree_helper.dart';
import 'launcher_state.dart';

/// Cubit managing launcher tile entries.
///
/// Loads entries from [LauncherStore], supports CRUD operations,
/// reordering, and folder navigation.
class LauncherCubit extends Cubit<LauncherState> {
  /// Store for persisting launcher entries.
  final LauncherStore store;

  /// Creates a [LauncherCubit] with the given [store].
  LauncherCubit({required this.store}) : super(const LauncherInitial());

  /// Loads all launcher entries from persistence.
  void loadEntries() {
    emit(const LauncherLoading());
    try {
      final entries = store.getEntries();
      emit(LauncherLoaded(allEntries: entries));
    } catch (e) {
      emit(LauncherError(e.toString()));
    }
  }

  /// Adds a new launcher entry and reloads.
  Future<void> addEntry(LauncherEntry entry) async {
    await store.addEntry(entry);
    reloadKeepingState();
  }

  /// Removes a launcher entry by [id] and reloads.
  ///
  /// Deleting a folder re-parents its children to the deleted folder's own
  /// parent (the grandparent level) rather than deleting them with the folder.
  Future<void> removeEntry(String id) async {
    final currentState = state;
    if (currentState is LauncherLoaded) {
      final match = currentState.allEntries.where((e) => e.id == id).toList();
      if (match.isNotEmpty && match.first.isFolder) {
        final grandParent = match.first.parentId;
        final updated = [
          for (final e in currentState.allEntries)
            if (e.id != id)
              e.parentId == id
                  ? e.copyWith(
                      parentId: grandParent,
                      clearParent: grandParent == null,
                    )
                  : e,
        ];
        await store.setEntries(updated);
        reloadKeepingState();
        return;
      }
    }
    await store.removeEntry(id);
    reloadKeepingState();
  }

  /// Updates an existing launcher entry and reloads.
  Future<void> updateEntry(LauncherEntry entry) async {
    await store.updateEntry(entry);
    reloadKeepingState();
  }

  /// Reorders the tiles at the currently open level by moving the sibling at
  /// [oldIndex] to [newIndex].
  ///
  /// Indices are into the visible siblings (children of `openFolderId`, or the
  /// top level). Tiles at other levels keep their folder membership; only the
  /// affected siblings are resequenced within the global `sortOrder` ordering.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;

    final siblings = currentState.allEntries
        .where((e) => e.parentId == currentState.openFolderId)
        .toList();
    // Match the reorder grid's display order: pinned tiles first, then manual
    // sortOrder — so oldIndex/newIndex line up with what the user dragged.
    LauncherSort.manual.sort(siblings);
    final indicesOutOfRange =
        oldIndex < 0 ||
        oldIndex >= siblings.length ||
        newIndex < 0 ||
        newIndex >= siblings.length;
    if (indicesOutOfRange) {
      return;
    }
    final moved = siblings.removeAt(oldIndex);
    siblings.insert(newIndex, moved);

    // Splice the reordered siblings back into their global positions, then
    // renumber sortOrder across the whole list.
    final siblingIds = currentState.allEntries
        .where((e) => e.parentId == currentState.openFolderId)
        .map((e) => e.id)
        .toSet();
    final all = List<LauncherEntry>.from(currentState.allEntries);
    var k = 0;
    for (var i = 0; i < all.length; i++) {
      if (siblingIds.contains(all[i].id)) {
        all[i] = siblings[k];
        k++;
      }
    }

    await store.reorderEntries(all);
    emit(currentState.copyWith(allEntries: store.getEntries()));
  }

  /// Opens the folder tile [id], showing its children in place.
  void openFolder(String id) {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    emit(currentState.copyWith(openFolderId: id));
  }

  /// Climbs one level up from the open folder (to its parent folder, or the
  /// top level when the open folder sits at the root).
  void closeFolder() {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    final open = currentState.allEntries
        .where((e) => e.id == currentState.openFolderId)
        .toList();
    final parent = open.isEmpty ? null : open.first.parentId;
    emit(
      currentState.copyWith(
        openFolderId: parent,
        clearOpenFolder: parent == null,
      ),
    );
  }

  /// Groups the [draggedId] and [targetId] tiles into a new folder named
  /// [name], created at the target's position and current level.
  Future<void> createFolderFrom(
    String draggedId,
    String targetId,
    String name,
  ) async {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    final all = List<LauncherEntry>.from(currentState.allEntries);
    final target = all.firstWhere((e) => e.id == targetId);

    final folderId = DateTime.now().microsecondsSinceEpoch.toString();
    final folder = LauncherEntry(
      id: folderId,
      folderPath: '',
      label: name,
      action: LauncherEntry.folderAction,
      iconName: 'folder',
      backgroundColor: target.backgroundColor,
      fontColor: target.fontColor,
      iconColor: target.iconColor,
      sortOrder: target.sortOrder,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      parentId: currentState.openFolderId,
    );

    for (var i = 0; i < all.length; i++) {
      if (all[i].id == draggedId || all[i].id == targetId) {
        all[i] = all[i].copyWith(parentId: folderId);
      }
    }
    all.add(folder);
    await store.setEntries(all);
    reloadKeepingState();
  }

  /// Moves the [draggedId] tile into the folder [folderId].
  ///
  /// No-op when the move would create a cycle (a folder into itself or one of
  /// its own descendants).
  Future<void> moveIntoFolder(String draggedId, String folderId) async {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    // ponytail: drag targets are always siblings so this can't trip via drag;
    // insurance against future non-drag callers.
    if (LauncherTreeHelper.wouldCreateCycle(
      currentState.allEntries,
      draggedId,
      folderId,
    )) {
      return;
    }
    await _reparent(currentState, draggedId, folderId);
  }

  /// Ejects the [childId] tile out of its folder, one level up (to the
  /// folder's parent, or the top level for a root folder).
  Future<void> moveToParent(String childId) async {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    final child = currentState.allEntries
        .where((e) => e.id == childId)
        .toList();
    if (child.isEmpty || child.first.parentId == null) return;
    final parent = currentState.allEntries
        .where((e) => e.id == child.first.parentId)
        .toList();
    final grandParent = parent.isEmpty ? null : parent.first.parentId;
    await _reparent(currentState, childId, grandParent);
  }

  /// Persists [id] relocated under [parentId] (`null` = top level) and reloads.
  Future<void> _reparent(
    LauncherLoaded currentState,
    String id,
    String? parentId,
  ) async {
    final updated = [
      for (final e in currentState.allEntries)
        e.id == id
            ? e.copyWith(parentId: parentId, clearParent: parentId == null)
            : e,
    ];
    await store.setEntries(updated);
    reloadKeepingState();
  }

  /// Toggles reorder mode on/off.
  void toggleReorderMode() {
    final currentState = state;
    if (currentState is! LauncherLoaded) return;
    emit(currentState.copyWith(isReorderMode: !currentState.isReorderMode));
  }

  /// Reloads entries while preserving reorder mode and the open
  /// folder level.
  ///
  /// Use this over [loadEntries] whenever the launcher is merely re-shown
  /// (tab change, tile added) — [loadEntries] is a cold load and drops the
  /// open sub-grid back to the top level.
  void reloadKeepingState() {
    final currentState = state;
    final entries = store.getEntries();

    if (currentState is LauncherLoaded) {
      emit(currentState.copyWith(allEntries: entries));
    } else {
      emit(LauncherLoaded(allEntries: entries));
    }
  }
}
