import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie loading indicator. Consistent sizing + semantics across the app.
/// Falls back to Icons.hourglass_top when:
/// - The asset file is missing (development setup)
/// - The user has enabled 'Reduce Motion' / prefers-reduced-motion in OS settings
class LoadingLottie extends StatelessWidget {
  final double size;
  final String semanticsLabel;

  const LoadingLottie({
    super.key,
    this.size = 120,
    this.semanticsLabel = 'Generating sticker',
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      return _FallbackIcon(
        size: size,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: Lottie.asset(
        'assets/animations/generating.json',
        width: size,
        height: size,
        repeat: true,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackIcon(
            size: size,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _FallbackIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.hourglass_top, size: size * 0.5, color: color),
    );
  }
}
