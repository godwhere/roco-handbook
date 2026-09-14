import 'package:flutter/material.dart';

import 'catalog_asset_image.dart';

class PetTypeCardBackground extends StatelessWidget {
  const PetTypeCardBackground({
    required this.types,
    required this.child,
    this.grid = false,
    this.warmLight = false,
    super.key,
  });

  final List<String> types;
  final Widget child;
  final bool grid;
  final bool warmLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryType = types.lastOrNull;
    final secondaryType = types.length > 1 ? types.first : null;
    final primary = petTypeAccentColor(
      primaryType,
      fallback: theme.colorScheme.primary,
      warmLight: warmLight,
    );
    final secondary = petTypeAccentColor(secondaryType, fallback: primary);
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final primaryTint = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.30 : 0.22),
      surface,
    );
    final secondaryTint = Color.alphaBlend(
      secondary.withValues(alpha: isDark ? 0.24 : 0.17),
      surface,
    );

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            key: const ValueKey('pet-type-card-gradient'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  primaryTint,
                  Color.alphaBlend(
                    surface.withValues(alpha: isDark ? 0.76 : 0.86),
                    primaryTint,
                  ),
                  secondaryTint,
                ],
                stops: const <double>[0, 0.52, 1],
              ),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.32 : 0.18),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _PetTypeMotifPainter(
                primary: primary,
                secondary: secondary,
                surface: surface,
                grid: grid,
                isDark: isDark,
              ),
            ),
          ),
        ),
        if (primaryType != null)
          Positioned.fill(
            child: ExcludeSemantics(
              child: Align(
                alignment: grid
                    ? const Alignment(0.52, -0.64)
                    : const Alignment(0.88, 0.34),
                child: Opacity(
                  opacity: isDark ? 0.07 : 0.09,
                  child: Image.asset(
                    typeIconAsset(primaryType) ?? '',
                    width: grid ? 112 : 76,
                    height: grid ? 112 : 76,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: Align(
              alignment: grid
                  ? const Alignment(0.76, 0.76)
                  : const Alignment(0.78, 0.72),
              child: Icon(
                Icons.pets_rounded,
                size: grid ? 40 : 38,
                color: primary.withValues(alpha: isDark ? 0.07 : 0.08),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

Color petTypeAccentColor(
  String? typeName, {
  required Color fallback,
  bool warmLight = false,
}) {
  final normalized = typeName?.endsWith('\u7cfb') == true
      ? typeName!.substring(0, typeName.length - 1)
      : typeName;
  return switch (normalized) {
    '\u666e\u901a' => const Color(0xFF7C91A8),
    '\u8349' => const Color(0xFF45C985),
    '\u706b' => const Color(0xFFF36A45),
    '\u6c34' => const Color(0xFF58A7F8),
    '\u5149' => warmLight ? const Color(0xFFF2C84B) : const Color(0xFF62C2F4),
    '\u5730' => const Color(0xFFC29A55),
    '\u51b0' => const Color(0xFF7CD5E8),
    '\u9f99' => const Color(0xFFE25570),
    '\u7535' => const Color(0xFFF0C419),
    '\u6bd2' => const Color(0xFFA56AE2),
    '\u866b' => const Color(0xFF91C93E),
    '\u6b66' => const Color(0xFFE8893F),
    '\u7ffc' => const Color(0xFF42BFC5),
    '\u840c' => const Color(0xFFF07FAE),
    '\u5e7d' => const Color(0xFF7E5AC7),
    '\u6076' => const Color(0xFF6D638D),
    '\u673a\u68b0' => const Color(0xFF4AAEA7),
    '\u5e7b' => const Color(0xFF8B86DF),
    _ => fallback,
  };
}

class _PetTypeMotifPainter extends CustomPainter {
  const _PetTypeMotifPainter({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.grid,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final bool grid;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..color = surface.withValues(alpha: isDark ? 0.16 : 0.50)
      ..style = PaintingStyle.fill;
    final curve = Path()
      ..moveTo(size.width * 0.18, 0)
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.54,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.92,
        size.width * 0.10,
        size.height * 0.46,
      )
      ..close();
    canvas.drawPath(curve, wash);

    final ringCenter = grid
        ? Offset(size.width * 0.50, size.height * 0.30)
        : Offset(size.width * 0.23, size.height * 0.48);
    final ringRadius = grid ? size.shortestSide * 0.29 : size.height * 0.38;
    canvas.drawCircle(
      ringCenter,
      ringRadius,
      Paint()
        ..color = primary.withValues(alpha: isDark ? 0.10 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = grid ? 7 : 5,
    );
    canvas.drawCircle(
      ringCenter,
      ringRadius * 0.76,
      Paint()
        ..color = secondary.withValues(alpha: isDark ? 0.07 : 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawSparkle(
      canvas,
      Offset(size.width * 0.72, size.height * 0.18),
      grid ? 8 : 7,
      primary.withValues(alpha: isDark ? 0.20 : 0.32),
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.12, size.height * 0.22),
      grid ? 4 : 3,
      secondary.withValues(alpha: isDark ? 0.16 : 0.24),
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * 0.22,
        center.dy - radius * 0.22,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.22,
        center.dy + radius * 0.22,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.22,
        center.dy + radius * 0.22,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.22,
        center.dy - radius * 0.22,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PetTypeMotifPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.surface != surface ||
      oldDelegate.grid != grid ||
      oldDelegate.isDark != isDark;
}
