import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/launcher_cubit.dart';
import '../cubit/launcher_state.dart';
import '../models/launcher_entry.dart';
import '../models/launcher_strings.dart';
import '../models/launcher_style.dart';
import 'launcher_drag_feedback.dart';
import 'launcher_eject_button.dart';
import 'launcher_folder_dialogs.dart';
import 'launcher_tile_widget.dart';

enum _DropZone { before, after, group }

/// Drag grid for reordering siblings and grouping tiles into folders.
class LauncherReorderGrid extends StatefulWidget {
  /// Current level and folder child counts.
  final LauncherLoaded state;

  /// Tiles at the current level, in manual order.
  final List<LauncherEntry> entries;

  /// Shared appearance settings.
  final LauncherStyle style;

  /// Translatable text.
  final LauncherStrings strings;

  /// Creates a reorder grid.
  const LauncherReorderGrid({
    super.key,
    required this.state,
    required this.entries,
    this.style = const LauncherStyle(),
    this.strings = const LauncherStrings(),
  });

  @override
  State<LauncherReorderGrid> createState() => _LauncherReorderGridState();
}

class _LauncherReorderGridState extends State<LauncherReorderGrid> {
  static const _edgeFraction = 0.3;
  final _dragLabel = ValueNotifier<String?>(null);
  final Map<int, GlobalKey> _itemKeys = {};
  int? _hoverIndex;
  _DropZone? _hoverZone;
  Offset _dragAnchor = Offset.zero;

  GlobalKey _key(int index) => _itemKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void dispose() {
    _dragLabel.dispose();
    super.dispose();
  }

  void _updateHover(int index, Offset offset) {
    final box = _key(index).currentContext?.findRenderObject() as RenderBox?;
    final dx = box?.globalToLocal(offset + _dragAnchor).dx ?? 0;
    final width = box?.size.width ?? 0;
    final zone = width == 0 || dx > width * (1 - _edgeFraction)
        ? _DropZone.after
        : dx < width * _edgeFraction
        ? _DropZone.before
        : _DropZone.group;
    _dragLabel.value = zone == _DropZone.group
        ? widget.strings.dropGroup
        : widget.strings.dropReorder;
    if (_hoverIndex != index || _hoverZone != zone) {
      setState(() {
        _hoverIndex = index;
        _hoverZone = zone;
      });
    }
  }

  void _clearHover() {
    if (mounted && (_hoverIndex != null || _hoverZone != null)) {
      setState(() {
        _hoverIndex = null;
        _hoverZone = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final size =
        (MediaQuery.sizeOf(context).width -
            style.gridSpacing * (style.columns + 1)) /
        style.columns;
    return GridView.builder(
      padding: EdgeInsets.all(style.gridSpacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: style.columns,
        mainAxisSpacing: style.gridSpacing,
        crossAxisSpacing: style.gridSpacing,
      ),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) => _item(index, size),
    );
  }

  Widget _item(int index, double size) {
    final entry = widget.entries[index];
    final tile = LauncherTileWidget(
      entry: entry,
      style: widget.style,
      strings: widget.strings,
      folderChildCount: entry.isFolder
          ? widget.state.folderChildCount(entry.id)
          : 0,
    );
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onMove: (details) {
        if (details.data != index) _updateHover(index, details.offset);
      },
      onLeave: (_) => _clearHover(),
      onAcceptWithDetails: (details) {
        final zone = _hoverIndex == index ? _hoverZone : null;
        _clearHover();
        _handleDrop(details.data, index, zone);
      },
      builder: (context, _, _) {
        final draggable = LongPressDraggable<int>(
          data: index,
          dragAnchorStrategy: (draggable, context, position) {
            _dragAnchor = childDragAnchorStrategy(draggable, context, position);
            return _dragAnchor;
          },
          onDragStarted: () {
            HapticFeedback.mediumImpact();
            _dragLabel.value = widget.strings.dropReorder;
          },
          onDragEnd: (_) {
            _clearHover();
            _dragLabel.value = null;
          },
          feedback: LauncherDragFeedback(
            tile: tile,
            size: size,
            radius: widget.style.cornerRadius,
            label: _dragLabel,
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: _dropVisual(
            index,
            KeyedSubtree(key: _key(index), child: tile),
          ),
        );
        if (widget.state.openFolderId == null) return draggable;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            draggable,
            Positioned(
              top: 0,
              right: 0,
              child: LauncherEjectButton(
                label: widget.strings.moveOutOfFolder,
                onPressed: () =>
                    context.read<LauncherCubit>().moveToParent(entry.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dropVisual(int index, Widget keyed) {
    final zone = _hoverIndex == index ? _hoverZone : null;
    final color =
        widget.style.highlightColor ?? Theme.of(context).colorScheme.primary;
    if (zone == _DropZone.group) {
      return Transform.scale(
        scale: 1.12,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.style.cornerRadius),
            border: Border.all(color: color, width: 3),
          ),
          child: keyed,
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        keyed,
        if (zone == _DropZone.before)
          Positioned(left: -3, top: 0, bottom: 0, child: _insertionBar(color)),
        if (zone == _DropZone.after)
          Positioned(right: -3, top: 0, bottom: 0, child: _insertionBar(color)),
      ],
    );
  }

  Widget _insertionBar(Color color) => Container(
    width: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Future<void> _handleDrop(int from, int to, _DropZone? zone) async {
    final entries = widget.entries;
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= entries.length ||
        to >= entries.length) {
      return;
    }
    final cubit = context.read<LauncherCubit>();
    final dragged = entries[from];
    final target = entries[to];
    if (zone == _DropZone.group) {
      if (target.isFolder) {
        final ok = await confirmLauncherAddToFolder(
          context,
          target.label,
          widget.strings,
        );
        if (ok) await cubit.moveIntoFolder(dragged.id, target.id);
      } else {
        final name = await promptLauncherFolderName(context, widget.strings);
        if (name != null && name.trim().isNotEmpty) {
          await cubit.createFolderFrom(dragged.id, target.id, name.trim());
        }
      }
      return;
    }
    final toAdjusted = to > from ? to - 1 : to;
    await cubit.reorder(
      from,
      zone == _DropZone.after ? toAdjusted + 1 : toAdjusted,
    );
  }
}
