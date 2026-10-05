import 'package:flutter/material.dart';

class EncabezadoPlebiscito extends StatelessWidget {
  final String pregunta;
  final int totalVotos;
  final int? limiteVotantes;
  final Duration tiempoRestante;
  final bool cerrada;
  final bool anonima;

  const EncabezadoPlebiscito({
    super.key,
    required this.pregunta,
    required this.totalVotos,
    required this.limiteVotantes,
    required this.tiempoRestante,
    required this.cerrada,
    required this.anonima,
  });

  String _textoRestante() {
    if (tiempoRestante.inDays >= 1) {
      final dias = tiempoRestante.inDays;
      return 'Cierra en $dias ${dias == 1 ? 'día' : 'días'}';
    }
    if (tiempoRestante.inHours >= 1) {
      return 'Cierra en ${tiempoRestante.inHours} h';
    }
    return 'Cierra en ${tiempoRestante.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(90),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'PLEBISCITO VECINAL · DOLORES HIDALGO',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pregunta,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Dato(
                icono: Icons.groups_rounded,
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: totalVotos),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, valor, _) => Text(
                    limiteVotantes == null
                        ? '$valor votos'
                        : '$valor / $limiteVotantes votos',
                  ),
                ),
              ),
              _Dato(
                icono: cerrada ? Icons.lock_clock_rounded : Icons.timer_outlined,
                child: Text(cerrada ? 'Votación cerrada' : _textoRestante()),
              ),
              if (anonima)
                const _Dato(
                  icono: Icons.lock_outline_rounded,
                  child: Text('Voto secreto'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final Widget child;

  const _Dato({required this.icono, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
