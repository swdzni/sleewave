import 'package:flutter/material.dart';

class ImportButton extends StatelessWidget {
  const ImportButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.file_upload_rounded),
      label: const Text('Import'),
    );
  }
}
