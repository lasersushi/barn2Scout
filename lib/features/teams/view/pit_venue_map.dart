import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_pit_map.dart';

/// The Nexus venue pit map, drawn to scale. Starts fitted to the screen
/// width; pinch to zoom, drag to pan. Team 751's pit is highlighted with a
/// star and unassigned pits are hatched, matching the frc.nexus map.
class PitVenueMap extends StatelessWidget {
  const PitVenueMap({super.key, required this.map});

  final NexusPitMap map;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale 1 = the whole map fits the width; taller maps pan vertically.
        final width = constraints.maxWidth;
        final height = map.size.height * width / map.size.width;
        return InteractiveViewer(
          constrained: false,
          maxScale: 6,
          child: SizedBox(
            width: width,
            height: height,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: map.size,
                child: _MapCanvas(map: map),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Everything in Nexus map units; [PitVenueMap] scales it to the screen.
class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.map});

  final NexusPitMap map;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Stack(
        children: [
          for (final wall in map.walls)
            Positioned.fromRect(
              rect: wall,
              child: ColoredBox(color: cs.outlineVariant),
            ),
          for (final area in map.areas)
            Positioned.fromRect(rect: area.rect, child: _Area(area.label)),
          for (final label in map.labels)
            Positioned.fromRect(rect: label.rect, child: _Label(label.label)),
          for (final arrow in map.arrows)
            Positioned.fromRect(rect: arrow.rect, child: _Arrow(arrow)),
          for (final pit in map.pits)
            Positioned.fromRect(rect: pit.rect, child: _Pit(pit)),
        ],
      ),
    );
  }
}

class _Pit extends StatelessWidget {
  const _Pit(this.pit);

  final MapPit pit;

  bool get _isMyTeam => pit.team == AppConfig.myTeamNumber.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final team = pit.team;

    // Unassigned pit: hatched, showing its pit label instead of a team.
    if (team == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          border: Border.all(color: cs.outline, width: 1.5),
        ),
        child: CustomPaint(
          painter: _HatchPainter(cs.outlineVariant),
          child: _FitText(
            pit.label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final fg = _isMyTeam ? cs.onPrimary : cs.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _isMyTeam ? cs.primary : cs.surface,
        border: Border.all(color: cs.outline, width: 1.5),
      ),
      child: _FitText(
        team,
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: fg),
        trailing: _isMyTeam ? Icon(Icons.star, size: 30, color: fg) : null,
      ),
    );
  }
}

class _Area extends StatelessWidget {
  const _Area(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.secondaryContainer,
      child: _FitText(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return _FitText(
      label,
      style: TextStyle(
        fontSize: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Centered text that shrinks rather than overflowing its box, so a
/// five-digit team number still fits a small pit.
class _FitText extends StatelessWidget {
  const _FitText(this.text, {required this.style, this.trailing});

  final String text;
  final TextStyle style;
  final Widget? trailing; // stacked under the text, e.g. the 751 star

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center, style: style),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.arrow);

  final MapArrow arrow;

  @override
  Widget build(BuildContext context) {
    final color = switch (arrow.color) {
      'blue' => Colors.blue,
      'purple' => Colors.purple,
      'red' => Colors.red,
      'green' => Colors.green,
      'orange' => Colors.orange,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Transform.rotate(
      angle: arrow.angleDegrees * math.pi / 180,
      child: CustomPaint(
        painter: _ArrowPainter(color: color, isDouble: arrow.isDouble),
      ),
    );
  }
}

/// A vertical arrow filling its box, pointing up (and down when [isDouble]).
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.isDouble});

  final Color color;
  final bool isDouble;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final top = stroke;
    final bottom = size.height - stroke;
    final wing = size.width / 2 - stroke;

    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), paint);
    canvas.drawPath(
      Path()
        ..moveTo(cx - wing, top + wing)
        ..lineTo(cx, top)
        ..lineTo(cx + wing, top + wing),
      paint,
    );
    if (isDouble) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - wing, bottom - wing)
          ..lineTo(cx, bottom)
          ..lineTo(cx + wing, bottom - wing),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.isDouble != isDouble;
}

/// Diagonal stripes marking an unassigned pit.
class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5;
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 16) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}
