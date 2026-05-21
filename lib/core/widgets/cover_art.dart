import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    this.coverUrl,
    this.localCoverPath,
    this.size = 56,
    this.borderRadius = 10,
  });

  final String? coverUrl;
  final String? localCoverPath;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      borderRadius == 10 ? context.themeTokens.coverRadius : borderRadius,
    );
    Widget child;
    if (localCoverPath != null && File(localCoverPath!).existsSync()) {
      child = Image.file(File(localCoverPath!), fit: BoxFit.cover);
    } else if (coverUrl != null && coverUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _Fallback(size: size),
        placeholder: (context, url) => _Fallback(size: size),
      );
    } else {
      child = _Fallback(size: size);
    }
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          border: Border.all(color: context.palette.border),
        ),
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.palette.surfaceMuted),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.42,
        color: context.palette.tertiaryText,
      ),
    );
  }
}
