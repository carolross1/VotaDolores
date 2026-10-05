import 'package:flutter/material.dart';

import '../../modelos/resultado_opcion.dart';
import 'confeti.dart';

/// Pantalla completa semitransparente que revela al ganador con una
/// animacion de escala "rebote" (elasticOut) y un desvanecido.
/// Si hay un unico ganador, ademas lanza confeti (Reto 4).
class DialogoGanador extends StatelessWidget {
  final List<ResultadoOpcion> ganadores;
  final bool sinVotos;

  const DialogoGanador({
    super.key,
    required this.ganadores,
    required this.sinVotos,
  });

  @override
  Widget build(BuildContext context) {
    final hayGanador = !sinVotos && ganadores.length == 1;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Tocar fuera de la tarjeta cierra el dialogo.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          if (hayGanador) const Positioned.fill(child: Confeti()),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _entrada(_Tarjeta(ganadores: ganadores, sinVotos: sinVotos)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entrada(Widget contenido) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, opacidad, child) =>
          Opacity(opacity: opacidad, child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, escala, child) =>
            Transform.scale(scale: escala, child: child),
        child: contenido,
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final List<ResultadoOpcion> ganadores;
  final bool sinVotos;

  const _Tarjeta({required this.ganadores, required this.sinVotos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hayGanador = !sinVotos && ganadores.length == 1;
    final hayEmpate = !sinVotos && ganadores.length > 1;

    final IconData icono = hayGanador
        ? Icons.emoji_events_rounded
        : hayEmpate
            ? Icons.balance_rounded
            : Icons.hourglass_empty_rounded;
    final String titulo = hayGanador
        ? 'Ganador del plebiscito'
        : hayEmpate
            ? 'Hay un empate'
            : 'Aún no hay votos';

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
              ),
            ),
            child: Icon(icono, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (sinVotos)
            Text(
              'Cuando los vecinos voten, aquí aparecerá el resultado.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final g in ganadores) ...[
              Text(
                g.opcion.texto,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${g.porcentaje.toStringAsFixed(0)}% · '
                '${g.opcion.votos} ${g.opcion.votos == 1 ? 'voto' : 'votos'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 6),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
