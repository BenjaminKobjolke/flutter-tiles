import 'package:flutter/material.dart';

import 'drill_in_folder_picker_dialog.dart';

/// A destination folder offered by [DrillInFolderPickerDialog].
///
/// Callers map their domain type (a `Favorite` virtual folder, a
/// `LauncherEntry` folder tile) to nodes up front, so the dialog itself
/// contains no tree-walking or domain knowledge.
class FolderPickerNode {
  /// Stable identity of the folder (`Favorite.path` / `LauncherEntry.id`).
  final String id;

  /// Id of the containing folder, or `null` for a direct child of the root.
  final String? parentId;

  /// Display name of the folder itself.
  final String label;

  /// Precomputed ancestor trail including the folder itself
  /// (e.g. "Parent  /  Child"); the dialog prepends the root label.
  final String breadcrumb;

  /// Leading icon for the folder tile.
  final IconData icon;

  /// Icon color, or `null` for the default icon theme color.
  final Color? iconColor;

  /// Number of entries directly inside the folder (count-badge value).
  final int childCount;

  /// Whether the entry is pinned — pinned entries render before unpinned
  /// ones at every level.
  final bool pinned;

  /// Creates a [FolderPickerNode].
  const FolderPickerNode({
    required this.id,
    required this.parentId,
    required this.label,
    required this.breadcrumb,
    required this.icon,
    this.iconColor,
    required this.childCount,
    this.pinned = false,
  });
}

/// A selectable leaf entry offered by [DrillInFolderPickerDialog].
///
/// Unlike a [FolderPickerNode], tapping a leaf selects it immediately and
/// closes the dialog. Callers map their domain type (e.g. a non-virtual
/// `Favorite`) to leaves up front.
class FolderPickerLeaf {
  /// Stable identity of the leaf (`Favorite.path`).
  final String id;

  /// Id of the containing folder, or `null` for a direct child of the root.
  final String? parentId;

  /// Display name of the leaf.
  final String label;

  /// Leading icon for the leaf tile.
  final IconData icon;

  /// Icon color, or `null` for the default icon theme color.
  final Color? iconColor;

  /// Whether the entry is pinned — pinned entries render before unpinned
  /// ones at every level.
  final bool pinned;

  /// Creates a [FolderPickerLeaf].
  const FolderPickerLeaf({
    required this.id,
    required this.parentId,
    required this.label,
    required this.icon,
    this.iconColor,
    this.pinned = false,
  });
}

/// Pre-translated chrome strings for [DrillInFolderPickerDialog] — each
/// feature passes its own `TK*` translations.
class FolderPickerLabels {
  /// Dialog title.
  final String title;

  /// Label of the confirm button ("Use this folder"), or `null` to hide the
  /// confirm button (leaf-only pickers where only leaves are selectable).
  final String? confirmLabel;

  /// Breadcrumb label for the root level.
  final String rootLabel;

  /// Message shown when the current level has no subfolders.
  final String emptyLabel;

  /// Label of an optional bottom action entry (e.g. "Add favorite"), or
  /// `null` for no action entry. Tapping it pops
  /// [FolderPickerSelection.isAction].
  final String? actionLabel;

  /// Cancel button label.
  final String cancelLabel;

  /// Back button tooltip.
  final String backLabel;

  /// Search field hint.
  final String searchHint;

  /// Creates a [FolderPickerLabels].
  const FolderPickerLabels({
    required this.title,
    this.confirmLabel,
    required this.rootLabel,
    required this.emptyLabel,
    this.actionLabel,
    this.cancelLabel = 'Cancel',
    this.backLabel = 'Back',
    this.searchHint = 'Search folders...',
  });
}

/// Confirmed selection of [DrillInFolderPickerDialog]; a non-null result means
/// the user picked something (dismissal yields `null` instead). Exactly one of
/// the three outcomes applies: confirm ([folderId], possibly `null` = root),
/// leaf tap ([leafId]), or action tap ([isAction]).
class FolderPickerSelection {
  /// Id of the chosen folder, or `null` for the root level.
  final String? folderId;

  /// Id of the tapped leaf, or `null` when a folder level was confirmed.
  final String? leafId;

  /// `true` when the bottom action entry was tapped.
  final bool isAction;

  /// Creates a [FolderPickerSelection].
  const FolderPickerSelection(
    this.folderId, {
    this.leafId,
    this.isAction = false,
  });
}
