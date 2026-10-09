import 'launcher_entry.dart';

/// Available tile sort modes.
enum LauncherSortMode { manual, label, dateCreated, mostUsed }

/// Sorts launcher entries while keeping pinned entries first.
class LauncherSort {
  /// Creates a launcher sort choice.
  const LauncherSort({
    this.mode = LauncherSortMode.manual,
    this.descending = false,
  });

  /// Manual tile order.
  static const manual = LauncherSort();

  /// Sort mode.
  final LauncherSortMode mode;

  /// Reverses label and creation date order, and follows the source app's
  /// inverted direction for usage counts.
  final bool descending;

  /// Sorts [entries] in place. Usage counts are keyed by entry id.
  void sort(
    List<LauncherEntry> entries, {
    Map<String, int> usageCounts = const {},
  }) {
    entries.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      switch (mode) {
        case LauncherSortMode.manual:
          return a.sortOrder.compareTo(b.sortOrder);
        case LauncherSortMode.label:
          final result = _compareLabels(a, b);
          return descending ? -result : result;
        case LauncherSortMode.dateCreated:
          final result = a.createdAtMs.compareTo(b.createdAtMs);
          return descending ? -result : result;
        case LauncherSortMode.mostUsed:
          final result = (usageCounts[b.id] ?? 0).compareTo(
            usageCounts[a.id] ?? 0,
          );
          if (result != 0) return descending ? result : -result;
          return _compareLabels(a, b);
      }
    });
  }

  static int _compareLabels(LauncherEntry a, LauncherEntry b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());
}
