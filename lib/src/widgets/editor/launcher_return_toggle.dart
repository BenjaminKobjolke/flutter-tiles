import 'package:flutter/material.dart';
import '../../models/launcher_strings.dart';

/// Shared "Return to launcher on back" switch used by both launcher tile
/// editors (dialog and full screen).
///
/// The host decides what this preference means when handling back navigation.
class LauncherReturnToggle extends StatelessWidget {
  /// Current toggle value.
  final bool value;

  /// Called when the user flips the switch.
  final ValueChanged<bool> onChanged;

  /// Translatable label.
  final LauncherStrings strings;

  /// Creates a [LauncherReturnToggle].
  const LauncherReturnToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.strings = const LauncherStrings(),
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(strings.returnToLauncherOnBack),
      value: value,
      onChanged: onChanged,
    );
  }
}
