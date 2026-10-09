import 'package:flutter/material.dart';
import '../../models/launcher_entry.dart';
import '../../models/launcher_strings.dart';
import '../../utils/launcher_tree_helper.dart';
import 'drill_in_folder_picker_dialog.dart';

/// Result of [LauncherFolderPickerDialog]: the chosen destination for a move.
class LauncherFolderPick {
  /// Id of the chosen folder tile, or `null` for the top level.
  final String? parentId;

  /// Label of the chosen destination, for display before the move is applied.
  final String label;

  /// Creates a [LauncherFolderPick].
  const LauncherFolderPick({required this.parentId, required this.label});

  /// Returns [entry] relocated to this destination.
  ///
  /// The top level needs `clearParent`: copyWith's `?? this.parentId` can't
  /// unset an id.
  LauncherEntry applyTo(LauncherEntry entry) => parentId == null
      ? entry.copyWith(clearParent: true)
      : entry.copyWith(parentId: parentId);
}

/// Picker that chooses a destination for moving a launcher tile: the top
/// level, or any folder tile — a thin adapter over
/// [DrillInFolderPickerDialog] (the same drill-in navigator the favorites
/// move flow uses). When moving a folder, pass [LauncherEntry.id] as
/// `excludeFolderId` so the folder and its descendants are not offered
/// (a folder cannot move into its own subtree).
class LauncherFolderPickerDialog {
  LauncherFolderPickerDialog._();

  /// Shows the picker over [allEntries]. Returns the chosen destination, or
  /// `null` if dismissed. [excludeFolderId] hides that folder and its
  /// descendants from the offered destinations.
  static Future<LauncherFolderPick?> show(
    BuildContext context, {
    required List<LauncherEntry> allEntries,
    String? excludeFolderId,
    LauncherStrings strings = const LauncherStrings(),
    Color? highlightColor,
  }) async {
    final excluded = excludeFolderId == null
        ? const <String>{}
        : {
            excludeFolderId,
            ...LauncherTreeHelper.descendantIds(allEntries, excludeFolderId),
          };

    final folders = [
      for (final e in allEntries)
        if (e.isFolder && !excluded.contains(e.id))
          FolderPickerNode(
            id: e.id,
            parentId: e.parentId,
            label: e.label,
            breadcrumb: LauncherTreeHelper.ancestors(
              allEntries,
              e.id,
            ).map((a) => a.label).join('  /  '),
            icon: Icons.folder_outlined,
            childCount: LauncherTreeHelper.childCount(allEntries, e.id),
          ),
    ];

    final selection = await DrillInFolderPickerDialog.show(
      context,
      folders: folders,
      highlightColor: highlightColor,
      labels: FolderPickerLabels(
        title: strings.moveToFolder,
        confirmLabel: strings.useThisFolder,
        rootLabel: strings.rootLevel,
        emptyLabel: strings.folderEmpty,
        cancelLabel: strings.cancel,
        backLabel: strings.back,
        searchHint: strings.folderSearchHint,
      ),
    );

    if (selection == null) return null;
    final folderId = selection.folderId;
    if (folderId == null) {
      return LauncherFolderPick(parentId: null, label: strings.rootLevel);
    }
    return LauncherFolderPick(
      parentId: folderId,
      label:
          LauncherTreeHelper.ancestorLabelPath(allEntries, folderId) ??
          folderId,
    );
  }
}
