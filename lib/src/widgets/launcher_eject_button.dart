import 'package:flutter/material.dart';

/// Moves a child tile to its parent level while reordering.
class LauncherEjectButton extends StatelessWidget {
  /// Creates the button that moves a tile to its parent level.
  const LauncherEjectButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// Accessible tooltip for the button.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Tooltip(
        message: label,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.arrow_upward, size: 16, color: Colors.white),
        ),
      ),
    ),
  );
}
