import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'launcher_editor_config.dart';

/// Runs a host-provided icon loader and prevents overlapping requests.
class LauncherCustomIconButton extends StatefulWidget {
  /// Icon source selected for the edited tile.
  final LauncherCustomIconSource source;

  /// Current settings draft passed to the host loader.
  final LauncherTileSettingsDraft draft;

  /// Called when the host returns an icon bitmap.
  final ValueChanged<Uint8List> onLoaded;

  /// Creates the custom icon loading button.
  const LauncherCustomIconButton({
    super.key,
    required this.source,
    required this.draft,
    required this.onLoaded,
  });

  @override
  State<LauncherCustomIconButton> createState() =>
      _LauncherCustomIconButtonState();
}

class _LauncherCustomIconButtonState extends State<LauncherCustomIconButton> {
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.source.load(context, widget.draft);
      if (bytes != null && mounted) widget.onLoaded(bytes);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _loading ? null : _load,
    icon: _loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(widget.source.icon),
    label: Text(widget.source.label),
  );
}
