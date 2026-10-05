import 'package:flutter/material.dart';

import '../../modelos/resultado_opcion.dart';

class BarraOpcion extends StatelessWidget {
  final ResultadoOpcion resultado;
  final int indice;
  final bool esLider;
  final bool puedeVotar;
  final VoidCallback onVotar;

  const BarraOpcion({
    super.key,
    required this.resultado,
    required this.indice,
    required this.esLider,
    required this.puedeVotar,
    required this.onVotar,
  });

  static const Color _dorado = Color(0xFFF59E0B);
  static const Color _doradoClaro = Color(0xFFFCD34D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final colorInicio = esLider ? _dorado : scheme.primary;
    final colorFin = esLider ? _doradoClaro : scheme.tertiary;
    final letra = String.fromCharCode(65 + indice);
    final votos = resultado.opcion.votos;

    final tarjeta = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: esLider ? _dorado : scheme.outlineVariant,
          width: esLider ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(esLider ? 28 : 14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: esLider ? _dorado : scheme.primary.withAlpha(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  letra,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: esLider ? Colors.white : scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resultado.opcion.texto,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (esLider)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.workspace_premium_rounded, color: _dorado),
                ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: resultado.porcentaje),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => Text(
                  '${valor.round()}%',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: resultado.porcentaje / 100,
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, _) => Container(
                      height: 14,
                      width: constraints.maxWidth * valor,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          colors: [colorInicio, colorFin],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$votos ${votos == 1 ? 'voto' : 'votos'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (puedeVotar)
                FilledButton.tonalIcon(
                  onPressed: onVotar,
                  icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                  label: const Text('Votar'),
                ),
            ],
          ),
        ],
      ),
    );

    // Entrada escalonada: cada tarjeta aparece un poco despues de la anterior.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + indice * 120),
      curve: Curves.easeOutCubic,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - valor)),
          child: child,
        ),
      ),
      child: tarjeta,
    );
  }
}
