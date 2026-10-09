import 'package:flutter/material.dart';

/// Visual settings shared by launcher tiles and the grid.
class LauncherStyle {
  /// Number of grid columns.
  final int columns;

  /// Space between tiles in pixels.
  final double gridSpacing;

  /// Tile corner radius in pixels.
  final double cornerRadius;

  /// Label font size in pixels.
  final double labelFontSize;

  /// Default label color.
  final Color labelColor;

  /// Whether folders show their child count.
  final bool showFolderCountBadge;

  /// Folder count font size in pixels.
  final double folderCountFontSize;

  /// Folder count text color.
  final Color folderCountFontColor;

  /// Folder count background color.
  final Color folderCountBackgroundColor;

  /// Picker highlight color; null uses the theme primary color.
  final Color? highlightColor;

  /// Creates launcher appearance settings with app-compatible defaults.
  const LauncherStyle({
    this.columns = 3,
    this.gridSpacing = 12,
    this.cornerRadius = 12,
    this.labelFontSize = 16,
    this.labelColor = Colors.white,
    this.showFolderCountBadge = true,
    this.folderCountFontSize = 16,
    this.folderCountFontColor = Colors.white,
    this.folderCountBackgroundColor = const Color(0x8A000000),
    this.highlightColor,
  });
}
