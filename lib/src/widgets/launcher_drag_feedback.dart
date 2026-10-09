import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tile preview with a live description of the pending drop.
class LauncherDragFeedback extends StatelessWidget {
  /// Creates the draggable tile preview.
  const LauncherDragFeedback({
    super.key,
    required this.tile,
    required this.size,
    required this.radius,
    required this.label,
  });

  /// Tile shown in the preview.
  final Widget tile;

  /// Width and height of the tile preview.
  /// Corner radius of the tile preview.
  final double size, radius;

  /// Live label describing the current drop action.
  final ValueListenable<String?> label;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1.1,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: label,
          builder: (_, text, _) => text == null
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(width: size, height: size, child: tile),
        ),
      ],
    ),
  );
}
