import 'package:flutter/material.dart';

/// Clarivo logo widget.
/// Shows the image logo from assets/images/clarivo_logo.png.
/// Falls back to a styled icon if the image is not yet present.
class ClarivoLogo extends StatelessWidget {
  const ClarivoLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/clarivo_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback while logo image is not yet added
        return _FallbackLogo(size: size);
      },
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.school_rounded,
        size: size * 0.55,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
