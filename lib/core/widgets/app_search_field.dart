import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.placeholder,
    required this.onChanged,
    this.onSubmitted,
  });

  final String placeholder;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: palette.primaryText),
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _hasText
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() => _hasText = false);
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
      onChanged: (value) {
        widget.onChanged(value);
        setState(() => _hasText = value.isNotEmpty);
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
