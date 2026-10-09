import 'package:flutter/material.dart';

import '../../models/launcher_strings.dart';
import '../pickers/launcher_folder_picker_dialog.dart';
import 'launcher_editor_config.dart';

/// Uses the host body wrapper, or the editor's default safe area.
Widget launcherEditorBody(
  BuildContext context,
  LauncherEditorConfig editor,
  Widget child,
) =>
    editor.bodyBuilder?.call(context, child) ??
    SafeArea(top: false, child: child);

/// Builds the tile pin switch.
Widget launcherPinSwitch(
  LauncherStrings strings,
  bool value,
  ValueChanged<bool> onChanged,
) => SwitchListTile(
  contentPadding: EdgeInsets.zero,
  secondary: const Icon(Icons.push_pin),
  title: Text(strings.pinTile),
  value: value,
  onChanged: onChanged,
);

/// Builds the optional host editor section with the shared section heading.
List<Widget> launcherSettingsSection(
  BuildContext context,
  LauncherStrings strings,
  Widget? editor,
) => editor == null
    ? const []
    : [
        const SizedBox(height: 16),
        Text(
          strings.settingsSection,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        editor,
      ];

/// Builds the required tile-name field.
Widget launcherNameField(
  TextEditingController controller,
  LauncherStrings strings,
  VoidCallback onChanged,
) => TextFormField(
  controller: controller,
  decoration: InputDecoration(
    labelText: strings.nameLabel,
    hintText: strings.nameHint,
    border: const OutlineInputBorder(),
  ),
  validator: (value) => value == null || value.trim().isEmpty ? '' : null,
  onChanged: (_) => onChanged(),
);

/// Builds the row that opens the folder destination picker.
Widget launcherMoveRow(
  LauncherFolderPick? move,
  LauncherStrings strings,
  VoidCallback onTap,
) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.drive_file_move_outline),
  title: Text(strings.moveToFolder),
  subtitle: move == null ? null : Text(move.label),
  trailing: const Icon(Icons.chevron_right),
  onTap: onTap,
);

/// Builds the editor's delete action.
Widget launcherDeleteButton(LauncherStrings strings, VoidCallback onPressed) =>
    OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete, color: Colors.red),
      label: Text(
        strings.deleteTile,
        style: const TextStyle(color: Colors.red),
      ),
    );

/// Shows the delete confirmation and returns whether deletion was confirmed.
Future<bool?> confirmLauncherDelete(
  BuildContext context,
  LauncherStrings strings,
) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(strings.deleteTile),
    content: Text(strings.deleteConfirm),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(strings.cancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(strings.delete, style: const TextStyle(color: Colors.red)),
      ),
    ],
  ),
);
