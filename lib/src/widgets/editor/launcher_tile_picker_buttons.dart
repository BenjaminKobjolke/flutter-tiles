import 'package:flutter/material.dart';

import '../../models/launcher_strings.dart';

/// Buttons that launch the icon and color pickers.
class LauncherTilePickerButtons extends StatelessWidget {
  /// Button labels.
  final LauncherStrings strings;

  /// Icon picker action.
  final VoidCallback onIcon;

  /// Background picker action.
  final VoidCallback onBackgroundColor;

  /// Label picker action.
  final VoidCallback onFontColor;

  /// Icon-color picker action.
  final VoidCallback onIconColor;

  /// Creates picker buttons.
  const LauncherTilePickerButtons({
    super.key,
    required this.strings,
    required this.onIcon,
    required this.onBackgroundColor,
    required this.onFontColor,
    required this.onIconColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: onIcon,
        icon: const Icon(Icons.palette),
        label: Text(strings.pickIcon),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onBackgroundColor,
        icon: const Icon(Icons.color_lens),
        label: Text(strings.pickBackgroundColor),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onFontColor,
        icon: const Icon(Icons.font_download),
        label: Text(strings.pickFontColor),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onIconColor,
        icon: const Icon(Icons.format_paint),
        label: Text(strings.pickIconColor),
      ),
    ],
  );
}
