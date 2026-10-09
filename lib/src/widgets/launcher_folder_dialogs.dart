import 'package:flutter/material.dart';
import '../models/launcher_strings.dart';

/// Prompts for a folder name when one tile is dropped onto another.
Future<String?> promptLauncherFolderName(
  BuildContext context,
  LauncherStrings strings,
) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.createFolderTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: strings.createFolderHint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

/// Confirms dropping a tile into an existing folder.
Future<bool> confirmLauncherAddToFolder(
  BuildContext context,
  String folderLabel,
  LauncherStrings strings,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folderLabel),
        content: Text(strings.addToFolderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.ok),
          ),
        ],
      ),
    ) ??
    false;
