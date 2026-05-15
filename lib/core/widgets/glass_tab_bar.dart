import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassTabItem {
  const GlassTabItem({
    required this.label,
    required this.icon,
    required this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
}

class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 62,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.palette.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.palette.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: itemWidth * currentIndex,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.palette.accent.withValues(
                              alpha: 0.22,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            Expanded(
                              child: _TabButton(
                                item: items[index],
                                active: index == currentIndex,
                                onTap: () => onTap(index),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final GlassTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: active ? 1.04 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 21,
                color: active
                    ? context.palette.primaryText
                    : context.palette.secondaryText,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: active ? 1 : 0.62,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? context.palette.primaryText
                        : context.palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
