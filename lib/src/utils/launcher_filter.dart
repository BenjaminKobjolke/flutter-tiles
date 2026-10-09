import '../models/launcher_entry.dart';

/// Filters launcher entries by label.
class LauncherFilter {
  LauncherFilter._();

  /// Keeps entries whose labels contain every space-separated query term.
  static List<LauncherEntry> apply(List<LauncherEntry> entries, String query) {
    if (query.trim().isEmpty) return entries;
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    return entries.where((entry) {
      final label = entry.label.toLowerCase();
      return terms.every(label.contains);
    }).toList();
  }
}
