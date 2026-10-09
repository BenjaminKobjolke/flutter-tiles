import 'package:flutter/widgets.dart';

import '../../models/launcher_entry.dart';

/// Mutable host-specific settings edited alongside a launcher tile.
class LauncherTileSettingsDraft {
  /// Optional folder target.
  String? folderPath;

  /// Optional file target.
  String? filePath;

  /// Action-specific fields; copied so cancelling never mutates the entry.
  final Map<String, String> extras;

  /// Creates a draft from the entry's existing settings.
  LauncherTileSettingsDraft({
    this.folderPath,
    this.filePath,
    Map<String, String> extras = const {},
  }) : extras = Map<String, String>.from(extras);
}

/// Builds the host's settings section, or null when none applies.
typedef LauncherTileSettingsBuilder =
    Widget? Function(
      BuildContext context,
      LauncherEntry entry,
      LauncherTileSettingsDraft draft,
      VoidCallback onChanged,
    );

/// Optional host settings for the generic tile editor.
class LauncherEditorConfig {
  /// Builder for action-specific settings.
  final LauncherTileSettingsBuilder? settingsSectionBuilder;

  /// Shows the host-specific return-on-back switch.
  final bool showReturnToggle;

  /// Creates editor configuration.
  const LauncherEditorConfig({
    this.settingsSectionBuilder,
    this.showReturnToggle = false,
  });
}
