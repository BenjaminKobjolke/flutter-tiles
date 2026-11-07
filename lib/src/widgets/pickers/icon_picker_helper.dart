import 'package:flutter/material.dart';

import '../../models/launcher_strings.dart';
import 'icon_picker_dialog.dart';

/// Opens the shared icon picker dialog.
class IconPickerHelper {
  /// Shows the picker and applies its choice while [context] is mounted.
  static Future<void> showAndApply(
    BuildContext context, {
    required IconData initialIcon,
    Color? highlightColor,
    LauncherStrings strings = const LauncherStrings(),
    required ValueChanged<IconPickerResult> onPicked,
  }) async {
    final result = await show(
      context,
      initialIcon: initialIcon,
      highlightColor: highlightColor,
      strings: strings,
    );
    if (result != null && context.mounted) onPicked(result);
  }

  /// Shows the icon picker and returns its choice, or `null` when cancelled.
  static Future<IconPickerResult?> show(
    BuildContext context, {
    required IconData initialIcon,
    Color? highlightColor,
    LauncherStrings strings = const LauncherStrings(),
  }) => showDialog<IconPickerResult>(
    context: context,
    builder: (context) => IconPickerDialog(
      initialIcon: initialIcon,
      highlightColor: highlightColor,
      strings: strings,
    ),
  );
}
