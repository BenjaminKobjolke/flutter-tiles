import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/launcher_entry.dart';

/// Live preview of an edited tile.
class LauncherTilePreview extends StatelessWidget {
  /// Original tile, used when the name is empty.
  final LauncherEntry entry;

  /// Current name.
  final String name;

  /// Current icon.
  final IconData icon;

  /// Current colors.
  final Color backgroundColor, fontColor, iconColor;

  /// Optional custom bitmap.
  final Uint8List? bitmap;

  /// Creates a tile preview.
  const LauncherTilePreview({
    super.key,
    required this.entry,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.fontColor,
    required this.iconColor,
    this.bitmap,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 120,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          color: bitmap != null ? Colors.transparent : backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (bitmap != null)
              Image.memory(
                bitmap!,
                excludeFromSemantics: true,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              )
            else
              FaIcon(FaIconData(icon), color: iconColor, size: 36),
            const SizedBox(height: 8),
            Text(
              name.isEmpty ? entry.label : name,
              style: TextStyle(
                color: fontColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}
