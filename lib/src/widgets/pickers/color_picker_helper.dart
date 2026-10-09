import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/launcher_strings.dart';

/// Shared color picker dialog helper.
///
/// Used across the app to avoid duplicating the AlertDialog+ColorPicker
/// pattern. Includes copy/paste hex color support with full alpha
/// (transparency) handling via the package's `colorToHex`/`colorFromHex`.
class ColorPickerHelper {
  /// Shows a color picker dialog and returns the selected color,
  /// or `null` if the user cancelled.
  ///
  /// [title] is the translation key for the dialog title.
  /// [initialColor] is the pre-selected color.
  static Future<Color?> showColorPicker(
    BuildContext context, {
    required String title,
    required Color initialColor,
    LauncherStrings strings = const LauncherStrings(),
  }) async {
    Color currentColor = initialColor;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: _buildContent(
            context: context,
            dialogContext: builderContext,
            currentColor: currentColor,
            strings: strings,
            // Rebuild on every change so the copy button always reads the
            // live color (incl. alpha), not a stale captured value.
            onColorChanged: (color) =>
                setDialogState(() => currentColor = color),
          ),
          actions: _buildActions(dialogContext, strings),
        ),
      ),
    );

    return saved == true ? currentColor : null;
  }

  /// Builds the dialog content with copy/paste buttons and the
  /// color picker widget.
  static Widget _buildContent({
    required BuildContext context,
    required BuildContext dialogContext,
    required Color currentColor,
    required LauncherStrings strings,
    required ValueChanged<Color> onColorChanged,
  }) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCopyPasteRow(
            context: context,
            dialogContext: dialogContext,
            currentColor: currentColor,
            strings: strings,
            onColorPasted: onColorChanged,
          ),
          ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            enableAlpha: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ],
      ),
    );
  }

  /// Builds the row containing copy and paste hex-color buttons.
  static Widget _buildCopyPasteRow({
    required BuildContext context,
    required BuildContext dialogContext,
    required Color currentColor,
    required LauncherStrings strings,
    required ValueChanged<Color> onColorPasted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: strings.copyHex,
          onPressed: () {
            final hex = colorToHex(
              currentColor,
              includeHashSign: true,
              enableAlpha: true,
            );
            Clipboard.setData(ClipboardData(text: hex));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(strings.colorCopied)));
          },
        ),
        IconButton(
          icon: const Icon(Icons.content_paste, size: 20),
          tooltip: strings.pasteHex,
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (!dialogContext.mounted) return;
            final parsed = colorFromHex(data?.text ?? '', enableAlpha: true);
            if (parsed != null) {
              onColorPasted(parsed);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(strings.invalidHex)));
              }
            }
          },
        ),
      ],
    );
  }

  /// Builds the Cancel and Save action buttons.
  static List<Widget> _buildActions(
    BuildContext dialogContext,
    LauncherStrings strings,
  ) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: Text(strings.cancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, true),
        child: Text(strings.save),
      ),
    ];
  }
}
