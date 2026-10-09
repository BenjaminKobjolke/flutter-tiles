import 'package:flutter/material.dart';
import '../models/launcher_strings.dart';

/// Why the launcher has no visible tiles.
enum LauncherEmptyCase {
  /// The top level has no tiles.
  noTiles,

  /// The current folder has no tiles.
  emptyFolder,

  /// A filter matches no tiles.
  noMatches,
}

/// Builds the host's empty state for a typed empty case.
typedef LauncherEmptyStateBuilder =
    Widget Function(BuildContext context, LauncherEmptyCase emptyCase);

/// Placeholder for an empty launcher level or a filter with no matches.
class LauncherEmptyState extends StatelessWidget {
  /// Creates the empty state for the current launcher level.
  const LauncherEmptyState({
    super.key,
    required this.strings,
    required this.emptyCase,
  });

  /// Text labels to display.
  final LauncherStrings strings;

  /// The current empty case.
  final LauncherEmptyCase emptyCase;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (emptyCase) {
              LauncherEmptyCase.noMatches => Icons.search_off,
              LauncherEmptyCase.emptyFolder => Icons.folder_open,
              LauncherEmptyCase.noTiles => Icons.dashboard,
            },
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            emptyCase == LauncherEmptyCase.emptyFolder
                ? strings.folderEmpty
                : strings.empty,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(strings.emptySubtitle),
        ],
      ),
    );
  }
}
