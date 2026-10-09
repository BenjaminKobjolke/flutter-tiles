import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/launcher_entry.dart';
import '../../models/launcher_style.dart';
import '../../models/launcher_strings.dart';
import '../../utils/launcher_icon_decoder.dart';
import '../launcher_tile_widget.dart';
import '../pickers/color_picker_helper.dart';
import '../pickers/icon_picker_dialog.dart';
import '../pickers/launcher_folder_picker_dialog.dart';
import 'launcher_editor_config.dart';
import 'launcher_return_toggle.dart';
import 'launcher_tile_edit_dialog.dart';
import 'launcher_tile_edit_controls.dart';
import 'launcher_tile_edit_leave_dialog.dart';
import 'launcher_tile_preview.dart';
import 'launcher_tile_picker_buttons.dart';

/// Full-screen editor for a launcher tile's label, icon, and colors.
///
/// Returns a [LauncherTileEditResult] on save, or `null` on cancel/back.
/// The delete button returns a special sentinel via [isLauncherTileDeleteResult].
class LauncherTileEditScreen extends StatefulWidget {
  /// The entry being edited.
  final LauncherEntry entry;

  /// Entries available as move destinations.
  final List<LauncherEntry> allEntries;

  /// Shared tile appearance.
  final LauncherStyle style;

  /// Translatable editor text.
  final LauncherStrings strings;

  /// Optional host-specific editor behavior.
  final LauncherEditorConfig editor;

  /// Creates a [LauncherTileEditScreen].
  const LauncherTileEditScreen({
    super.key,
    required this.entry,
    required this.allEntries,
    this.style = const LauncherStyle(),
    this.strings = const LauncherStrings(),
    this.editor = const LauncherEditorConfig(),
  });

  @override
  State<LauncherTileEditScreen> createState() => _LauncherTileEditScreenState();
}

class _LauncherTileEditScreenState extends State<LauncherTileEditScreen> {
  late final TextEditingController _nameController;
  late final LauncherTileSettingsDraft _draft;
  Widget? _settingsEditor;
  late IconData _selectedIcon;
  late String _selectedIconName;
  late Color _selectedColor;
  late Color _selectedFontColor;
  late Color _selectedIconColor;
  String? _selectedCustomIconBase64;
  Uint8List? _decodedCustomIcon;
  late bool _returnToLauncherOnBack;
  late bool _pinned;
  LauncherFolderPick? _move;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.label);
    _draft = LauncherTileSettingsDraft(
      folderPath: widget.entry.folderPath,
      filePath: widget.entry.filePath,
      extras: widget.entry.extras,
    );
    _selectedIcon = LauncherTileWidget.resolveIcon(widget.entry.iconName);
    _selectedIconName = widget.entry.iconName;
    _selectedColor = Color(widget.entry.backgroundColor);
    _selectedFontColor = Color(widget.entry.fontColor);
    _selectedIconColor = Color(widget.entry.iconColor);
    _selectedCustomIconBase64 = widget.entry.customIconBase64;
    _decodedCustomIcon = decodeLauncherIcon(_selectedCustomIconBase64);
    _returnToLauncherOnBack = widget.entry.returnToLauncherOnBack;
    _pinned = widget.entry.pinned;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty {
    final entry = widget.entry;
    final settingsDirty =
        _settingsEditor != null &&
        (_draft.folderPath != entry.folderPath ||
            _draft.filePath != entry.filePath ||
            !mapEquals(_draft.extras, entry.extras));
    return _nameController.text.trim() != entry.label ||
        _selectedIconName != entry.iconName ||
        _selectedColor != Color(entry.backgroundColor) ||
        _selectedFontColor != Color(entry.fontColor) ||
        _selectedIconColor != Color(entry.iconColor) ||
        _selectedCustomIconBase64 != entry.customIconBase64 ||
        _returnToLauncherOnBack != entry.returnToLauncherOnBack ||
        _pinned != entry.pinned ||
        _move != null ||
        settingsDirty;
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final choice = await showLauncherTileLeaveDialog(
      context,
      strings: widget.strings,
    );
    if (!mounted) return;
    switch (choice) {
      case LauncherTileLeaveChoice.save:
        _save();
      case LauncherTileLeaveChoice.discard:
        Navigator.of(context).pop();
      case LauncherTileLeaveChoice.cancel:
      case null:
        break;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      LauncherTileEditResult(
        label: _nameController.text.trim(),
        iconName: _selectedIconName,
        iconData: _selectedIcon,
        backgroundColor: _selectedColor,
        fontColor: _selectedFontColor,
        iconColor: _selectedIconColor,
        clearCustomIcon:
            widget.entry.customIconBase64 != null &&
            _selectedCustomIconBase64 == null,
        returnToLauncherOnBack: _returnToLauncherOnBack,
        pinned: _pinned,
        folderPath: _settingsEditor != null ? _draft.folderPath : null,
        filePath: _settingsEditor != null ? _draft.filePath : null,
        extras: _settingsEditor != null ? _draft.extras : null,
        move: _move,
      ),
    );
  }

  Future<void> _pickMoveTarget() async {
    final pick = await LauncherFolderPickerDialog.show(
      context,
      allEntries: widget.allEntries,
      strings: widget.strings,
      highlightColor: widget.style.highlightColor,
      // A folder must not be offered itself or its subtree as a destination.
      excludeFolderId: widget.entry.isFolder ? widget.entry.id : null,
    );
    if (pick == null || !mounted) return;
    setState(() => _move = pick);
  }

  Future<void> _pickColor(
    String title,
    Color initial,
    ValueChanged<Color> apply,
  ) async {
    final color = await ColorPickerHelper.showColorPicker(
      context,
      title: title,
      initialColor: initial,
      strings: widget.strings,
    );
    if (color != null && mounted) setState(() => apply(color));
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<IconPickerResult>(
      context: context,
      builder: (context) => IconPickerDialog(
        initialIcon: _selectedIcon,
        highlightColor: widget.style.highlightColor,
        strings: widget.strings,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedIcon = result.iconData;
        _selectedIconName = result.name;
        // User picked a Font Awesome icon — drop any external bitmap so the
        // tile re-renders from the new glyph.
        _selectedCustomIconBase64 = null;
        _decodedCustomIcon = null;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await confirmLauncherDelete(context, widget.strings);
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const DeleteSentinel());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.strings.editTile),
          actions: [
            TextButton(onPressed: _save, child: Text(widget.strings.save)),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LauncherTilePreview(
                  entry: widget.entry,
                  name: _nameController.text,
                  icon: _selectedIcon,
                  backgroundColor: _selectedColor,
                  fontColor: _selectedFontColor,
                  iconColor: _selectedIconColor,
                  bitmap: _decodedCustomIcon,
                ),
                const SizedBox(height: 24),
                launcherNameField(
                  _nameController,
                  widget.strings,
                  () => setState(() {}),
                ),
                ...launcherSettingsSection(
                  context,
                  widget.strings,
                  _settingsEditor ??= widget.editor.settingsSectionBuilder
                      ?.call(context, widget.entry, _draft, _onSettingsChanged),
                ),
                const SizedBox(height: 16),
                LauncherTilePickerButtons(
                  strings: widget.strings,
                  onIcon: _pickIcon,
                  onBackgroundColor: () => _pickColor(
                    widget.strings.pickBackgroundColor,
                    _selectedColor,
                    (c) => _selectedColor = c,
                  ),
                  onFontColor: () => _pickColor(
                    widget.strings.pickFontColor,
                    _selectedFontColor,
                    (c) => _selectedFontColor = c,
                  ),
                  onIconColor: () => _pickColor(
                    widget.strings.pickIconColor,
                    _selectedIconColor,
                    (c) => _selectedIconColor = c,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.editor.showReturnToggle)
                  LauncherReturnToggle(
                    strings: widget.strings,
                    value: _returnToLauncherOnBack,
                    onChanged: (v) =>
                        setState(() => _returnToLauncherOnBack = v),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.push_pin),
                  title: Text(widget.strings.pinTile),
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                ),
                launcherMoveRow(_move, widget.strings, _pickMoveTarget),
                const SizedBox(height: 24),
                launcherDeleteButton(widget.strings, _confirmDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
