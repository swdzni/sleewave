import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_action_button.dart';
import 'app_alert.dart';

Future<void> showAppErrorPopup({
  required BuildContext context,
  required String title,
  required String message,
  String? primaryLabel,
  VoidCallback? onPrimary,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss error',
    barrierColor: Colors.black.withValues(alpha: 0.08),
    transitionDuration: AppDurations.state,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: _ErrorPopupBody(
              title: title,
              message: message,
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.standard,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ErrorPopupBody extends StatelessWidget {
  const _ErrorPopupBody({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.elevated,
            borderRadius: BorderRadius.circular(tokens.floatingRadius),
            border: Border.all(color: palette.danger.withValues(alpha: 0.44)),
            boxShadow: palette.shadow.a == 0
                ? null
                : [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: tokens.shadowBlur,
                      offset: tokens.shadowOffset,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAlert(
                  title: title,
                  message: message,
                  variant: AppAlertVariant.danger,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppActionButton(
                        icon: Icons.close_rounded,
                        label: 'Dismiss',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (primaryLabel != null && onPrimary != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppActionButton(
                          icon: Icons.open_in_full_rounded,
                          label: primaryLabel!,
                          filled: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onPrimary!();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
