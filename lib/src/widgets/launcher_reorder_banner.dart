import 'package:flutter/material.dart';
import '../models/launcher_strings.dart';

/// Reorder instructions and the host's exit action.
class LauncherReorderBanner extends StatelessWidget {
  /// Creates the reorder instructions banner.
  const LauncherReorderBanner({
    super.key,
    required this.strings,
    this.highlightColor,
    required this.onExit,
  });

  /// Text shown in the banner.
  final LauncherStrings strings;

  /// Optional banner color; defaults to the theme's primary color.
  final Color? highlightColor;

  /// Called when the user exits reorder mode.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? Theme.of(context).colorScheme.primary;
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color,
      child: Row(
        children: [
          Icon(Icons.drag_handle, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.reorderHint,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: onExit,
            child: Text(
              strings.exitReorder,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
