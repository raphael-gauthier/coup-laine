// lib/presentation/widgets/map_pins.dart
//
// Marqueurs partagés pour les vues `flutter_map` :
// - `MapStatusPin` : pin client avec couleur de statut + count animaux.
// - `MapBasePin`   : pin home (base / pivot) avec icône custom.
// - `MapPinPainter`: peintre interne (cercle + tail + ombre + outline blanc).
//
// Utilisé par `map_screen.dart` (Map tab) et `proximity_map_view.dart`
// (création de tournée, onglet Carte).

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Pin client : disque coloré statut + queue + count animaux blanc au centre.
/// Si `selected` est vrai, affiche un badge check primary en haut à droite
/// (utilisé par la Carte du flow proximity / création tournée).
class MapStatusPin extends StatelessWidget {
  final Color color;
  final int animalCount;
  final bool selected;

  const MapStatusPin({
    super.key,
    required this.color,
    required this.animalCount,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final pin = SizedBox(
      width: 40,
      height: 48,
      child: CustomPaint(
        painter: MapPinPainter(color: color),
        child: Align(
          alignment: const Alignment(0, -0.25),
          child: Text(
            '$animalCount',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );

    if (!selected) return pin;

    return SizedBox(
      width: 48,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 2,
            child: pin,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colors.primary,
                shape: BoxShape.circle,
                border: const Border.fromBorderSide(
                  BorderSide(color: Color(0xFFFFFFFF), width: 1.5),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                FIcons.check,
                size: 10,
                color: theme.colors.primaryForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin "home" (base ou pivot) : disque coloré + queue + icône blanche au centre.
/// Par défaut, l'icône est `FIcons.house`. Le caller peut override (par ex.
/// `FIcons.target` pour le pivot d'une recherche par proximité).
class MapBasePin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const MapBasePin({
    super.key,
    required this.color,
    this.icon = FIcons.house,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: CustomPaint(
        painter: MapPinPainter(color: color),
        child: Align(
          // Disc center is at y = 22; nudge ~2px up to compensate for the
          // icon-font baseline offset so the glyph reads as truly centered.
          alignment: const Alignment(0, -0.286),
          child: Icon(
            icon,
            color: const Color(0xFFFFFFFF),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Peintre du pin : cercle + queue triangulaire + ombre + outline blanc.
/// Tracé proportionnel — fonctionne pour les deux tailles 40×48 et 48×56.
class MapPinPainter extends CustomPainter {
  final Color color;

  MapPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final discRadius = (size.width - 4) / 2;
    final discCenter = Offset(cx, discRadius);
    final tip = Offset(cx, size.height);
    final tailHalf = discRadius * 8.0 / 18.0;
    final tailY = discRadius + tailHalf;

    final circle = Path()
      ..addOval(Rect.fromCircle(center: discCenter, radius: discRadius));
    final tail = Path()
      ..moveTo(cx - tailHalf, tailY)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(cx + tailHalf, tailY)
      ..close();
    final pin = Path.combine(PathOperation.union, circle, tail);

    canvas.drawShadow(pin, const Color(0x66000000), 2, false);

    canvas.drawPath(
      pin,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      pin,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant MapPinPainter oldDelegate) =>
      oldDelegate.color != color;
}
