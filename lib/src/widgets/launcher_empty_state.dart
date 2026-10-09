import 'package:flutter/material.dart';
import '../models/launcher_strings.dart';

/// Placeholder for an empty launcher level or a filter with no matches.
class LauncherEmptyState extends StatelessWidget {
  /// Creates the empty state for the current launcher level.
  const LauncherEmptyState({
    super.key,
    required this.strings,
    required this.insideFolder,
    required this.hasEntries,
  });

  /// Text labels to display.
  final LauncherStrings strings;

  /// Whether this level is inside a folder.
  /// Whether the level contains entries before filtering.
  final bool insideFolder, hasEntries;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasEntries
                ? Icons.search_off
                : insideFolder
                ? Icons.folder_open
                : Icons.dashboard,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            insideFolder && !hasEntries ? strings.folderEmpty : strings.empty,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(strings.emptySubtitle),
        ],
      ),
    );
  }
}
