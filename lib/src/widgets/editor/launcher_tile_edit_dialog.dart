import 'package:flutter/material.dart';

import '../../models/launcher_entry.dart';
import '../pickers/launcher_folder_picker_dialog.dart';

/// Result from the launcher tile edit screen.
class LauncherTileEditResult {
  /// Updated label.
  final String label;

  /// Updated icon field name.
  final String iconName;

  /// Updated icon data.
  final IconData iconData;

  /// Updated background color.
  final Color backgroundColor;

  /// Updated font color.
  final Color fontColor;

  /// Updated icon glyph color.
  final Color iconColor;

  /// Whether the caller should wipe the entry's `customIconBase64` on save.
  ///
  /// Set to `true` when the user picked a Font Awesome icon in the editor,
  /// replacing any external bitmap that was previously stored on the entry.
  /// `false` means "leave the bitmap as-is".
  final bool clearCustomIcon;

  /// Whether the system back button should return to the launcher tab after
  /// this tile's action.
  final bool returnToLauncherOnBack;

  /// Whether the tile is pinned (ordered before unpinned tiles at its level).
  final bool pinned;

  /// Updated target folder, when the type's inline settings editor changed it
  /// (open folder / photo / video / OCR). `null` leaves it unchanged.
  final String? folderPath;

  /// Updated target file, when the file settings editor changed it (open file).
  /// `null` leaves it unchanged.
  final String? filePath;

  /// Updated extras from the type's inline settings editor (e.g. `url`,
  /// `sub_item_id`, `note_*`). `null` leaves the entry's extras unchanged.
  final Map<String, String>? extras;

  /// Destination the user staged via the move picker, or `null` to leave the
  /// tile where it is. A pick with a `null` parentId means the top level.
  final LauncherFolderPick? move;

  /// Creates a [LauncherTileEditResult].
  const LauncherTileEditResult({
    required this.label,
    required this.iconName,
    required this.iconData,
    required this.backgroundColor,
    required this.fontColor,
    required this.iconColor,
    this.clearCustomIcon = false,
    this.returnToLauncherOnBack = true,
    this.pinned = false,
    this.folderPath,
    this.filePath,
    this.extras,
    this.move,
  });

  /// Applies the generic edits, optional host settings, and staged move.
  LauncherEntry applyTo(LauncherEntry entry) {
    final base = entry.copyWith(
      label: label,
      iconName: iconName,
      backgroundColor: backgroundColor.toARGB32(),
      fontColor: fontColor.toARGB32(),
      iconColor: iconColor.toARGB32(),
      returnToLauncherOnBack: returnToLauncherOnBack,
      pinned: pinned,
      folderPath: folderPath,
      filePath: filePath,
      extras: extras,
    );
    final updated = clearCustomIcon
        ? LauncherEntry(
            id: base.id,
            folderPath: base.folderPath,
            label: base.label,
            action: base.action,
            filePath: base.filePath,
            iconName: base.iconName,
            backgroundColor: base.backgroundColor,
            fontColor: base.fontColor,
            iconColor: base.iconColor,
            sortOrder: base.sortOrder,
            createdAtMs: base.createdAtMs,
            extras: base.extras,
            returnToLauncherOnBack: base.returnToLauncherOnBack,
            parentId: base.parentId,
            pinned: base.pinned,
          )
        : base;
    return move?.applyTo(updated) ?? updated;
  }
}

/// Sentinel value returned when the user confirms deletion.
class DeleteSentinel {
  /// Creates a [DeleteSentinel].
  const DeleteSentinel();
}

/// Returns `true` if the edit screen result indicates a delete action.
bool isLauncherTileDeleteResult(Object? result) => result is DeleteSentinel;
