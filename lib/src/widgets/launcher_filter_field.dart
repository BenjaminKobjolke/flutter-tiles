import 'package:flutter/material.dart';
import '../models/launcher_strings.dart';

/// Plain filter input for hosts without their own filter bar.
class LauncherFilterField extends StatefulWidget {
  /// Current query supplied by the host.
  final String query;

  /// Called whenever the query changes.
  final ValueChanged<String> onChanged;

  /// Translatable field text.
  final LauncherStrings strings;

  /// Creates a launcher filter field.
  const LauncherFilterField({
    super.key,
    required this.query,
    required this.onChanged,
    this.strings = const LauncherStrings(),
  });

  @override
  State<LauncherFilterField> createState() => _LauncherFilterFieldState();
}

class _LauncherFilterFieldState extends State<LauncherFilterField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant LauncherFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      hintText: widget.strings.filterHint,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: widget.query.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: widget.strings.clearSearch,
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            ),
    ),
  );
}
