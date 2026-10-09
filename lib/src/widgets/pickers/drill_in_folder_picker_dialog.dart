import 'package:flutter/material.dart';
import 'drill_in_folder_picker_models.dart';
export 'drill_in_folder_picker_models.dart';

/// Shared drill-in destination picker used by the favorites and launcher
/// "Move to folder" flows and the favorites destination pickers.
///
/// Starts at the root level and descends into subfolders on tap, with a
/// breadcrumb + back button to go up and a search box that flat-filters
/// entries by name across all levels. Tapping a folder only drills in;
/// selection happens via the confirm button ([FolderPickerLabels.confirmLabel],
/// picks the current level) or by tapping a [FolderPickerLeaf].
class DrillInFolderPickerDialog {
  DrillInFolderPickerDialog._();

  /// Shows the picker over [folders] (and optional selectable [leaves]).
  /// Returns the selection, or `null` if dismissed.
  ///
  /// [folders] must already exclude forbidden destinations (the moved folder
  /// itself and its descendants).
  static Future<FolderPickerSelection?> show(
    BuildContext context, {
    required List<FolderPickerNode> folders,
    List<FolderPickerLeaf> leaves = const [],
    required FolderPickerLabels labels,
    Color? highlightColor,
  }) {
    return showDialog<FolderPickerSelection>(
      context: context,
      builder: (context) => _FolderPickerDialog(
        folders: folders,
        leaves: leaves,
        labels: labels,
        highlightColor: highlightColor,
      ),
    );
  }
}

/// Stateful body of [DrillInFolderPickerDialog] — holds the current drill-in
/// level and search query. Pops with a [FolderPickerSelection].
class _FolderPickerDialog extends StatefulWidget {
  final List<FolderPickerNode> folders;
  final List<FolderPickerLeaf> leaves;
  final FolderPickerLabels labels;
  final Color? highlightColor;

  const _FolderPickerDialog({
    required this.folders,
    required this.leaves,
    required this.labels,
    this.highlightColor,
  });

  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  /// Current drill-in level; `null` = root.
  String? _currentParentId;
  String _searchQuery = '';

  Color get _highlightColor =>
      widget.highlightColor ?? Theme.of(context).colorScheme.primary;

  bool get _searching => _searchQuery.trim().isNotEmpty;

  /// Folders shown for the current state: flat name matches while searching,
  /// otherwise the direct children of the current level.
  List<FolderPickerNode> get _visibleFolders {
    if (_searching) {
      final q = _searchQuery.toLowerCase();
      return widget.folders
          .where((f) => f.label.toLowerCase().contains(q))
          .toList();
    }
    return widget.folders.where((f) => f.parentId == _currentParentId).toList();
  }

  /// Leaves shown for the current state — same filtering rules as
  /// [_visibleFolders].
  List<FolderPickerLeaf> get _visibleLeaves {
    if (_searching) {
      final q = _searchQuery.toLowerCase();
      return widget.leaves
          .where((l) => l.label.toLowerCase().contains(q))
          .toList();
    }
    return widget.leaves.where((l) => l.parentId == _currentParentId).toList();
  }

  FolderPickerNode? _nodeById(String? id) {
    if (id == null) return null;
    for (final f in widget.folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  void _drillInto(FolderPickerNode folder) {
    setState(() {
      _currentParentId = folder.id;
      _searchQuery = '';
    });
  }

  void _goUp() {
    setState(() {
      _currentParentId = _nodeById(_currentParentId)?.parentId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.labels.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_searching) _buildBreadcrumb(),
            _buildSearchField(),
            const SizedBox(height: 12),
            Flexible(child: _buildList()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.labels.cancelLabel),
        ),
        if (widget.labels.confirmLabel != null)
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, FolderPickerSelection(_currentParentId)),
            child: Text(widget.labels.confirmLabel!),
          ),
      ],
    );
  }

  /// Breadcrumb bar: back button (up one level) + the root-prefixed ancestor
  /// trail of the current level. Back is disabled at the root.
  Widget _buildBreadcrumb() {
    final current = _nodeById(_currentParentId);
    final rootLabel = widget.labels.rootLabel;
    final trail = current == null
        ? rootLabel
        : '$rootLabel  /  ${current.breadcrumb}';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: widget.labels.backLabel,
            onPressed: current == null ? null : _goUp,
          ),
          Expanded(
            child: Text(
              trail,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.labels.searchHint,
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildList() {
    final folders = _visibleFolders;
    final leaves = _visibleLeaves;
    final tiles = <Widget>[
      if (folders.isEmpty && leaves.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(widget.labels.emptyLabel, textAlign: TextAlign.center),
        )
      else ...[
        // Pinned entries first (matching SortHelper.sortFavorites: pin wins
        // over the folder/leaf grouping); each sublist keeps caller order.
        ...folders.where((f) => f.pinned).map(_buildFolderTile),
        ...leaves.where((l) => l.pinned).map(_buildLeafTile),
        ...folders.where((f) => !f.pinned).map(_buildFolderTile),
        ...leaves.where((l) => !l.pinned).map(_buildLeafTile),
      ],
      if (widget.labels.actionLabel != null) ...[
        const Divider(),
        _buildActionTile(),
      ],
    ];
    return ListView(shrinkWrap: true, children: tiles);
  }

  /// A tappable leaf row — selects immediately and closes the dialog.
  Widget _buildLeafTile(FolderPickerLeaf leaf) {
    return ListTile(
      onTap: () =>
          Navigator.pop(context, FolderPickerSelection(null, leafId: leaf.id)),
      leading: Icon(leaf.icon, color: leaf.iconColor),
      title: Text(leaf.label),
    );
  }

  /// The optional bottom action entry ("Add favorite"), shown at every level
  /// and during search.
  Widget _buildActionTile() {
    return ListTile(
      onTap: () => Navigator.pop(
        context,
        const FolderPickerSelection(null, isAction: true),
      ),
      leading: const Icon(Icons.add, color: Colors.green),
      title: Text(widget.labels.actionLabel!),
    );
  }

  /// A tappable folder row — icon, name, child-count badge, and a chevron.
  /// Tapping drills into the folder rather than selecting it; selection is the
  /// explicit confirm action.
  Widget _buildFolderTile(FolderPickerNode folder) {
    return ListTile(
      onTap: () => _drillInto(folder),
      leading: Icon(folder.icon, color: folder.iconColor),
      title: Text(folder.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChildCountBadge(folder.childCount),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }

  /// Small pill showing how many entries a folder contains.
  Widget _buildChildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _highlightColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 12, color: _highlightColor),
      ),
    );
  }
}
