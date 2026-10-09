import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/launcher_cubit.dart';
import '../cubit/launcher_state.dart';
import '../models/launcher_entry.dart';
import '../models/launcher_sort.dart';
import '../models/launcher_strings.dart';
import '../models/launcher_style.dart';
import '../utils/launcher_filter.dart';
import 'editor/launcher_editor_config.dart';
import 'editor/launcher_tile_edit_dialog.dart';
import 'editor/launcher_tile_edit_screen.dart';
import 'launcher_empty_state.dart';
import 'launcher_reorder_banner.dart';
import 'launcher_reorder_grid.dart';
import 'launcher_tile_widget.dart';

/// A launcher grid whose actions and filter UI are supplied by the host.
class LauncherView extends StatelessWidget {
  /// Shared appearance settings.
  final LauncherStyle style;

  /// Translatable launcher text.
  final LauncherStrings strings;

  /// Sort choice outside reorder mode.
  final LauncherSort sort;

  /// Per-entry usage counts for usage sorting.
  final Map<String, int> usageCounts;

  /// Host-owned filter text.
  final String filterQuery;

  /// Widget below the grid; receives the visible tile count.
  final Widget Function(BuildContext, int)? bottomBuilder;

  /// Host-specific editor settings.
  final LauncherEditorConfig editor;

  /// Tile tap action; folders are also delivered to the host.
  final ValueChanged<LauncherEntry>? onTileTap;

  /// Host action for leaving reorder mode.
  final VoidCallback? onExitReorder;

  /// Called for a long press on grid background.
  final VoidCallback? onBackgroundLongPress;

  /// Called after a tile is saved.
  final ValueChanged<LauncherEntry>? onTileUpdated;

  /// Called after a tile is deleted.
  final ValueChanged<LauncherEntry>? onTileDeleted;

  /// Creates a launcher view beneath a [BlocProvider] of [LauncherCubit].
  const LauncherView({
    super.key,
    this.style = const LauncherStyle(),
    this.strings = const LauncherStrings(),
    this.sort = LauncherSort.manual,
    this.usageCounts = const {},
    this.filterQuery = '',
    this.bottomBuilder,
    this.editor = const LauncherEditorConfig(),
    this.onTileTap,
    this.onExitReorder,
    this.onBackgroundLongPress,
    this.onTileUpdated,
    this.onTileDeleted,
  });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LauncherCubit, LauncherState>(
        builder: (context, state) {
          if (state is LauncherLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LauncherError) return Center(child: Text(state.message));
          if (state is! LauncherLoaded) return const SizedBox.shrink();
          return _loaded(context, state);
        },
      );

  Widget _loaded(BuildContext context, LauncherLoaded state) {
    final entries = state.entries;
    (state.isReorderMode ? LauncherSort.manual : sort).sort(
      entries,
      usageCounts: usageCounts,
    );
    final visible = state.isReorderMode
        ? entries
        : LauncherFilter.apply(entries, filterQuery);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          if (state.isReorderMode)
            LauncherReorderBanner(
              strings: strings,
              highlightColor: style.highlightColor,
              onExit:
                  onExitReorder ??
                  context.read<LauncherCubit>().toggleReorderMode,
            ),
          Expanded(
            child: visible.isEmpty
                ? LauncherEmptyState(
                    strings: strings,
                    insideFolder: state.openFolderId != null,
                    hasEntries: entries.isNotEmpty,
                  )
                : state.isReorderMode
                ? LauncherReorderGrid(
                    state: state,
                    entries: visible,
                    style: style,
                    strings: strings,
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: onBackgroundLongPress,
                    child: GridView.builder(
                      padding: EdgeInsets.all(style.gridSpacing),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: style.columns,
                        mainAxisSpacing: style.gridSpacing,
                        crossAxisSpacing: style.gridSpacing,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        return LauncherTileWidget(
                          entry: entry,
                          style: style,
                          strings: strings,
                          folderChildCount: entry.isFolder
                              ? state.folderChildCount(entry.id)
                              : 0,
                          onTap: () => onTileTap?.call(entry),
                          onLongPress: () => _edit(context, state, entry),
                        );
                      },
                    ),
                  ),
          ),
          if (bottomBuilder != null) bottomBuilder!(context, visible.length),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    LauncherLoaded state,
    LauncherEntry entry,
  ) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (context) => LauncherTileEditScreen(
          entry: entry,
          allEntries: state.allEntries,
          style: style,
          strings: strings,
          editor: editor,
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final cubit = context.read<LauncherCubit>();
    if (isLauncherTileDeleteResult(result)) {
      await cubit.removeEntry(entry.id);
      onTileDeleted?.call(entry);
    } else if (result is LauncherTileEditResult) {
      final updated = result.applyTo(entry);
      await cubit.updateEntry(updated);
      onTileUpdated?.call(updated);
    }
  }
}
