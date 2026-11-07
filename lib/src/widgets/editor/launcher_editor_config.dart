import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../models/launcher_entry.dart';
import '../pickers/color_picker_helper.dart';

/// Wraps the editor form with a host-provided scaffold body.
typedef LauncherEditorBodyBuilder =
    Widget Function(BuildContext context, Widget child);

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

  /// Creates a draft initialized with the editable settings from [entry].
  factory LauncherTileSettingsDraft.fromEntry(LauncherEntry entry) =>
      LauncherTileSettingsDraft(
        folderPath: entry.folderPath,
        filePath: entry.filePath,
        extras: entry.extras,
      );
}

/// Loads a custom icon for the edited tile using the current host settings.
///
/// Returning `null` means no icon was found and leaves the tile unchanged.
typedef LauncherCustomIconLoader =
    Future<Uint8List?> Function(
      BuildContext context,
      LauncherTileSettingsDraft draft,
    );

/// A host-provided action for loading a tile's custom bitmap icon.
class LauncherCustomIconSource {
  /// Text shown on the editor button; the host supplies translated text.
  final String label;

  /// Icon shown beside [label].
  final IconData icon;

  /// Loads PNG bytes using the live settings [draft].
  ///
  /// Return `null` to leave the icon unchanged; the host is responsible for
  /// showing any message when no icon is found or loading fails.
  final LauncherCustomIconLoader load;

  /// Creates a custom icon source with its host-provided label and loader.
  const LauncherCustomIconSource({
    required this.label,
    required this.icon,
    required this.load,
  });
}

/// Selects the custom icon source for a tile, or hides the custom icon button.
typedef LauncherCustomIconSourceBuilder =
    LauncherCustomIconSource? Function(LauncherEntry entry);

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
  /// Wraps the editor body; the host owns safe-area handling when set.
  final LauncherEditorBodyBuilder? bodyBuilder;

  /// Shows color picker copy and paste messages through the host.
  final ColorPickerMessageCallback? onColorPickerMessage;

  /// Builder for action-specific settings.
  final LauncherTileSettingsBuilder? settingsSectionBuilder;

  /// Selects an optional host action for loading a custom bitmap icon.
  final LauncherCustomIconSourceBuilder? customIconSource;

  /// Shows the host-specific return-on-back switch.
  final bool showReturnToggle;

  /// Creates editor configuration.
  const LauncherEditorConfig({
    this.bodyBuilder,
    this.onColorPickerMessage,
    this.settingsSectionBuilder,
    this.customIconSource,
    this.showReturnToggle = false,
  });
}
