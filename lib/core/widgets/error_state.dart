import 'package:flutter/material.dart';

import 'app_alert.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppAlert(
        title: 'Something went wrong',
        message: message,
        variant: AppAlertVariant.danger,
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
