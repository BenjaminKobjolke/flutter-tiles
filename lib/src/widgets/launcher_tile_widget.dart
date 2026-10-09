import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../generated/font_awesome_all_icons.dart';
import '../models/launcher_entry.dart';
import '../models/launcher_style.dart';
import '../models/launcher_strings.dart';
import '../utils/launcher_icon_decoder.dart';

/// A single launcher tile displaying an icon and label.
///
/// Renders with the entry's background color and a centered icon. Uses the
/// entry's [LauncherEntry.customIconBase64] PNG bytes when present (e.g. an
/// installed app's launcher icon), otherwise falls back to the Font Awesome
/// icon named by [LauncherEntry.iconName].
class LauncherTileWidget extends StatefulWidget {
  /// The launcher entry to display.
  final LauncherEntry entry;

  /// Shared appearance settings.
  final LauncherStyle style;

  /// Translatable launcher text.
  final LauncherStrings strings;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Number of direct children when this is a folder.
  final int folderChildCount;

  /// Creates a [LauncherTileWidget].
  const LauncherTileWidget({
    super.key,
    required this.entry,
    this.style = const LauncherStyle(),
    this.strings = const LauncherStrings(),
    this.folderChildCount = 0,
    this.onTap,
    this.onLongPress,
  });

  /// Resolves a Font Awesome field name to its [IconData].
  static IconData resolveIcon(String iconName) {
    final match = allFontAwesomeIcons.firstWhere(
      (e) => e.fieldName == iconName,
      orElse: () => allFontAwesomeIcons.first,
    );
    return match.iconData;
  }

  @override
  State<LauncherTileWidget> createState() => _LauncherTileWidgetState();
}

class _LauncherTileWidgetState extends State<LauncherTileWidget> {
  Uint8List? _decodedIconBytes;

  @override
  void initState() {
    super.initState();
    _decodeIfNeeded();
  }

  @override
  void didUpdateWidget(LauncherTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.customIconBase64 != widget.entry.customIconBase64) {
      _decodeIfNeeded();
    }
  }

  void _decodeIfNeeded() {
    final encoded = widget.entry.customIconBase64;
    _decodedIconBytes = decodeLauncherIcon(encoded);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final bgColor = Color(entry.backgroundColor);
    final labelSize = widget.style.labelFontSize;
    final iconBytes = _decodedIconBytes;

    return Semantics(
      label: _semanticLabel(entry),
      button: true,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.style.cornerRadius),
          ),
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildTileContent(entry, labelSize, iconBytes),
              if (entry.pinned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.push_pin,
                    size: labelSize,
                    color: Color(entry.fontColor).withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Label + folder item count for TalkBack (badge digits alone are meaningless).
  String _semanticLabel(LauncherEntry entry) {
    if (!entry.isFolder || widget.folderChildCount == 0) return entry.label;
    final count = widget.strings.folderItemCount.replaceFirst(
      '{count}',
      widget.folderChildCount.toString(),
    );
    return '${entry.label}, $count';
  }

  /// Builds the icon + label column that fills the tile.
  Widget _buildTileContent(
    LauncherEntry entry,
    double labelSize,
    Uint8List? iconBytes,
  ) {
    final showFolderCountBadge =
        entry.isFolder &&
        widget.folderChildCount > 0 &&
        widget.style.showFolderCountBadge;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                iconBytes != null
                    ? Image.memory(
                        iconBytes,
                        width: labelSize * 2,
                        height: labelSize * 2,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      )
                    : FaIcon(
                        FaIconData(
                          LauncherTileWidget.resolveIcon(entry.iconName),
                        ),
                        color: Color(entry.iconColor),
                        size: labelSize * 2,
                      ),
                if (showFolderCountBadge)
                  Positioned(
                    right: -labelSize * 0.6,
                    bottom: -labelSize * 0.4,
                    child: _CountBadge(
                      count: widget.folderChildCount,
                      // Badge stays proportionally small relative to the
                      // chosen badge font size.
                      fontSize: widget.style.folderCountFontSize * 0.7,
                      textColor: widget.style.folderCountFontColor,
                      backgroundColor: widget.style.folderCountBackgroundColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: labelSize * 1.2 * 2 + 8,
          child: Text(
            entry.label,
            style: TextStyle(
              color: Color(entry.fontColor),
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Small circular badge showing how many tiles a folder holds.
class _CountBadge extends StatelessWidget {
  /// Number to display.
  final int count;

  /// Font size for the number.
  final double fontSize;

  /// Text color for the number.
  final Color textColor;

  /// Background color of the badge.
  final Color backgroundColor;

  /// Creates a [_CountBadge].
  const _CountBadge({
    required this.count,
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Text(
        '$count',
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
