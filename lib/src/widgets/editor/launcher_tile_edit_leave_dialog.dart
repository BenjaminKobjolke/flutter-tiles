import 'package:flutter/material.dart';
import '../../models/launcher_strings.dart';

/// What the user chose when leaving the tile editor with unsaved edits.
enum LauncherTileLeaveChoice {
  /// Stay on the editor.
  cancel,

  /// Leave without saving.
  discard,

  /// Save, then leave.
  save,
}

/// Asks whether to save, discard or keep editing before leaving the tile
/// editor. Returns `null` when the dialog is dismissed by tapping outside.
Future<LauncherTileLeaveChoice?> showLauncherTileLeaveDialog(
  BuildContext context, {
  LauncherStrings strings = const LauncherStrings(),
}) {
  return showDialog<LauncherTileLeaveChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.unsavedTitle),
      content: Text(strings.unsavedMessage),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, LauncherTileLeaveChoice.cancel),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, LauncherTileLeaveChoice.discard),
          child: Text(strings.unsavedDiscard),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, LauncherTileLeaveChoice.save),
          child: Text(strings.save),
        ),
      ],
    ),
  );
}
