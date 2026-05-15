import 'package:flutter/material.dart';

class FolderHeader extends StatelessWidget {
  const FolderHeader({super.key, required this.path, required this.onImport});

  final String path;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleewave Library',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(path, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.file_upload_rounded),
          label: const Text('Import'),
        ),
      ],
    );
  }
}
