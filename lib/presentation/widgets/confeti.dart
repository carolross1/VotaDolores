import 'dart:math';

import 'package:flutter/material.dart';

/// Reto 4: confeti dibujado a mano con un CustomPainter, sin paquetes externos.
class Confeti extends StatefulWidget {
  final Duration duracion;
  final int cantidad;

  const Confeti({
    super.key,
    this.duracion = const Duration(seconds: 4),
    this.cantidad = 90,
  });

  @override
  State<Confeti> createState() => _ConfetiState();
}

class _ConfetiState extends State<Confeti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particula> _particulas;

  @override
  void initState() {
    super.initState();
    final azar = Random();
    _particulas =
        List.generate(widget.cantidad, (_) => _Particula.aleatoria(azar));
    _controller = AnimationController(vsync: this, duration: widget.duracion)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfetiPainter(_particulas, _controller),
      ),
    );
  }
}

const List<Color> _coloresConfeti = [
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFFFACC15),
];

class _Particula {
  final double x; // posicion horizontal inicial (0 a 1)
  final double retraso; // cuando empieza a caer (0 a 0.35 del total)
  final double velocidad; // que tan rapido cae
  final double balanceo; // cuanto se mueve de lado a lado
  final double fase;
  final double frecuencia;
  final double giro;
  final double ancho;
  final double alto;
  final Color color;

  const _Particula({
    required this.x,
    required this.retraso,
    required this.velocidad,
    required this.balanceo,
    required this.fase,
    required this.frecuencia,
    required this.giro,
    required this.ancho,
    required this.alto,
    required this.color,
  });

  factory _Particula.aleatoria(Random r) {
    return _Particula(
      x: r.nextDouble(),
      retraso: r.nextDouble() * 0.35,
      velocidad: 0.7 + r.nextDouble() * 0.6,
      balanceo: 0.01 + r.nextDouble() * 0.03,
      fase: r.nextDouble() * 2 * pi,
      frecuencia: 1 + r.nextDouble() * 2,
      giro: (r.nextDouble() - 0.5) * 14,
      ancho: 6 + r.nextDouble() * 6,
      alto: 10 + r.nextDouble() * 8,
      color: _coloresConfeti[r.nextInt(_coloresConfeti.length)],
    );
  }
}

class _ConfetiPainter extends CustomPainter {
  final List<_Particula> particulas;
  final Animation<double> animacion;

  _ConfetiPainter(this.particulas, this.animacion) : super(repaint: animacion);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animacion.value;
    final pintura = Paint();

    for (final p in particulas) {
      final local = ((t - p.retraso) / (1 - p.retraso)).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;

      final y = -0.05 + local * p.velocidad * 1.2;
      if (y > 1.05) continue;

      final x = p.x + sin(local * 2 * pi * p.frecuencia + p.fase) * p.balanceo;

      // se desvanece en el ultimo tramo de su caida
      final opacidad = local > 0.85 ? (1 - local) / 0.15 : 1.0;
      pintura.color =
          p.color.withAlpha((255 * opacidad).round().clamp(0, 255).toInt());

      // efecto de volteo: la tira se "achata" al girar
      final volteo = 0.25 + 0.75 * cos(local * 10 * p.frecuencia + p.fase).abs();

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.giro * local * pi);
      canvas.scale(1.0, volteo);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.ancho, height: p.alto),
          const Radius.circular(2),
        ),
        pintura,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetiPainter oldDelegate) =>
      oldDelegate.animacion != animacion;
}
