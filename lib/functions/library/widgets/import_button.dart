import 'package:flutter/material.dart';

import '../../../core/widgets/app_action_button.dart';

class ImportButton extends StatelessWidget {
  const ImportButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppActionButton(
      filled: true,
      onPressed: onPressed,
      icon: Icons.file_upload_rounded,
      label: 'Import',
    );
  }
}
