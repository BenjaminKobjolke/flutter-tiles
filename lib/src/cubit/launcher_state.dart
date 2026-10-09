import '../models/launcher_entry.dart';
import '../utils/launcher_tree_helper.dart';

/// Base state for the launcher cubit.
abstract class LauncherState {
  /// Creates a launcher state.
  const LauncherState();
}

/// Initial state before entries are loaded.
class LauncherInitial extends LauncherState {
  /// Creates the initial state.
  const LauncherInitial();
}

/// Loading state while entries are being fetched.
class LauncherLoading extends LauncherState {
  /// Creates the loading state.
  const LauncherLoading();
}

/// Loaded state with entries and reorder mode.
class LauncherLoaded extends LauncherState {
  /// All launcher entries.
  final List<LauncherEntry> allEntries;

  /// Whether reorder mode is active.
  final bool isReorderMode;

  /// Id of the folder tile currently open, or `null` for the top level.
  final String? openFolderId;

  /// Creates a loaded state.
  const LauncherLoaded({
    required this.allEntries,
    this.isReorderMode = false,
    this.openFolderId,
  });

  /// Entries at the currently open level.
  List<LauncherEntry> get entries =>
      allEntries.where((e) => e.parentId == openFolderId).toList();

  /// Number of tiles nested inside the folder tile [folderId].
  int folderChildCount(String folderId) =>
      LauncherTreeHelper.childCount(allEntries, folderId);

  /// Creates a copy with the given fields replaced.
  ///
  /// Pass [clearOpenFolder] to return to the top level, since the
  /// `?? this.openFolderId` idiom cannot otherwise reset it to null.
  LauncherLoaded copyWith({
    List<LauncherEntry>? allEntries,
    bool? isReorderMode,
    String? openFolderId,
    bool clearOpenFolder = false,
  }) {
    return LauncherLoaded(
      allEntries: allEntries ?? this.allEntries,
      isReorderMode: isReorderMode ?? this.isReorderMode,
      openFolderId: clearOpenFolder
          ? null
          : (openFolderId ?? this.openFolderId),
    );
  }
}

/// Error state.
class LauncherError extends LauncherState {
  /// Error message.
  final String message;

  /// Creates an error state with [message].
  const LauncherError(this.message);
}
