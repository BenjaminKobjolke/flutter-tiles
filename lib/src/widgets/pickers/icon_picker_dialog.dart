import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../generated/font_awesome_all_icons.dart';
import '../../models/launcher_strings.dart';

/// Result from the icon picker dialog.
class IconPickerResult {
  /// Selected Font Awesome field name.
  final String name;

  /// Selected icon data.
  final IconData iconData;

  /// Creates a selected icon result.
  const IconPickerResult({required this.name, required this.iconData});
}

/// A dialog with a searchable, filterable grid of all Font Awesome icons.
///
/// Returns an [IconPickerResult] when an icon is selected, or null if cancelled.
class IconPickerDialog extends StatefulWidget {
  /// Icon initially selected in the dialog.
  final IconData? initialIcon;

  /// Accent color for selection highlights. Falls back to the theme's
  /// primary color when null.
  final Color? highlightColor;

  /// Dialog labels.
  final LauncherStrings strings;

  /// Creates the searchable icon picker.
  const IconPickerDialog({
    super.key,
    this.initialIcon,
    this.highlightColor,
    this.strings = const LauncherStrings(),
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFieldName;
  FaIconCategory? _selectedCategory;

  List<FaIconEntry> get _filteredIcons {
    var icons = allFontAwesomeIcons;

    // Filter by category
    if (_selectedCategory != null) {
      icons = icons
          .where((entry) => entry.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      icons = icons.where((entry) {
        if (entry.displayName.contains(query)) return true;
        if (entry.fieldName.toLowerCase().contains(query)) return true;
        return entry.searchKeywords.any((kw) => kw.contains(query));
      }).toList();
    }

    return icons;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialIcon != null) {
      for (final entry in allFontAwesomeIcons) {
        if (entry.iconData.codePoint == widget.initialIcon!.codePoint) {
          _selectedFieldName = entry.fieldName;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIcons;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.strings.iconPickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildSearchField(),
            const SizedBox(height: 8),
            _buildCategoryFilter(),
            _buildResultCount(context, filtered.length),
            _buildIconGrid(filtered),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Search text field with a clear-button suffix.
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.strings.iconPickerSearch,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: widget.strings.clearSearch,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  /// Row of category filter chips (all / solid / regular / brands).
  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: widget.strings.iconPickerAll,
            selected: _selectedCategory == null,
            onSelected: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            label: widget.strings.iconPickerSolid,
            selected: _selectedCategory == FaIconCategory.solid,
            onSelected: () =>
                setState(() => _selectedCategory = FaIconCategory.solid),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            label: widget.strings.iconPickerRegular,
            selected: _selectedCategory == FaIconCategory.regular,
            onSelected: () =>
                setState(() => _selectedCategory = FaIconCategory.regular),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            label: widget.strings.iconPickerBrands,
            selected: _selectedCategory == FaIconCategory.brands,
            onSelected: () =>
                setState(() => _selectedCategory = FaIconCategory.brands),
          ),
        ],
      ),
    );
  }

  /// Left-aligned "N results" count label.
  Widget _buildResultCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.strings.iconPickerCount.replaceFirst('{count}', '$count'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Builds the icon grid view with the given [filtered] icon list.
  Widget _buildIconGrid(List<FaIconEntry> filtered) {
    return Flexible(
      child: filtered.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Icon(Icons.search_off, size: 48, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildIconCell(filtered[index]),
            ),
    );
  }

  /// Single selectable icon cell for [entry] in the picker grid.
  Widget _buildIconCell(FaIconEntry entry) {
    final isSelected = entry.fieldName == _selectedFieldName;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(
          IconPickerResult(name: entry.fieldName, iconData: entry.iconData),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: entry.displayName,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            border: isSelected
                ? Border.all(
                    color:
                        widget.highlightColor ??
                        Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FaIconData(entry.iconData),
                size: 24,
                color: isSelected
                    ? widget.highlightColor ??
                          Theme.of(context).colorScheme.primary
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected
                  ? widget.highlightColor ??
                        Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
