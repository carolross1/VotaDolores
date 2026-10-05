import 'package:flutter/material.dart';

import '../datos/repositorio_votacion.dart';
import '../logica/resultado_voto.dart';
import '../logica/servicio_votacion.dart';
import '../modelos/opcion_votacion.dart';
import '../modelos/votacion.dart';
import 'widgets/barra_opcion.dart';
import 'widgets/dialogo_ganador.dart';
import 'widgets/encabezado_plebiscito.dart';

class VotacionScreen extends StatefulWidget {
  const VotacionScreen({super.key});

  @override
  State<VotacionScreen> createState() => _VotacionScreenState();
}

class _VotacionScreenState extends State<VotacionScreen> {
  final RepositorioVotacion _repo = RepositorioVotacion();
  late Votacion _votacion;
  late ServicioVotacion _servicio;
  String _idUsuario = '';
  bool _cargando = true;

  bool get _yaVote => _votacion.votantes.contains(_idUsuario);

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final fechaGuardada = await _repo.leerFechaCierre();
    final votacion = Votacion(
      pregunta: '¿Qué obra prioritaria debe realizar el municipio este año?',
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitación del Jardín Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: 'alumbrado', texto: 'Alumbrado en el Barrio de Analco'),
        OpcionVotacion(id: 'parque', texto: 'Parque Infantil en la Colonia Guanajuato'),
      ],
      fechaCierre: fechaGuardada ?? DateTime.now().add(const Duration(days: 7)),
      limiteVotantes: 500,
      anonima: true,
    );
    await _repo.restaurar(votacion);
    final id = await _repo.leerOCrearIdUsuario();
    await _repo.guardar(votacion);

    if (!mounted) return;
    setState(() {
      _votacion = votacion;
      _servicio = ServicioVotacion(votacion);
      _idUsuario = id;
      _cargando = false;
    });
  }

  Future<void> _votar(String idOpcion) async {
    final resultado =
        _servicio.registrarVoto(idUsuario: _idUsuario, idOpcion: idOpcion);
    switch (resultado) {
      case ResultadoVoto.exitoso:
        setState(() {});
        await _repo.guardar(_votacion);
      case ResultadoVoto.usuarioYaVoto:
        _mensaje('Ya registramos tu voto en este plebiscito.');
      case ResultadoVoto.votacionCerrada:
        _mensaje('Esta votación ya cerró.');
      case ResultadoVoto.limiteAlcanzado:
        _mensaje('Se alcanzó el límite de votantes de este plebiscito.');
      case ResultadoVoto.opcionInvalida:
        _mensaje('Esa opción no existe.');
    }
  }

  Future<void> _nuevoVotante() async {
    final id = 'invitado-${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _idUsuario = id);
    await _repo.guardarIdUsuario(id);
  }

  Future<void> _reiniciar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reiniciar plebiscito?'),
        content: const Text(
          'Se borrarán todos los votos guardados en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await _repo.borrar();
    if (!mounted) return;
    setState(() => _cargando = true);
    await _iniciar();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  void _verGanador() {
    final total = _servicio.totalVotos;
    final ids = _servicio.determinarGanador().map((o) => o.id).toSet();
    final ganadores = _servicio
        .obtenerResultados()
        .where((r) => ids.contains(r.opcion.id))
        .toList();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      useSafeArea: false,
      builder: (_) => DialogoGanador(ganadores: ganadores, sinVotos: total == 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fondo = Color.alphaBlend(scheme.primary.withAlpha(16), scheme.surface);

    if (_cargando) {
      return Scaffold(
        backgroundColor: fondo,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final resultados = _servicio.obtenerResultados();
    final maxPorcentaje =
        resultados.map((r) => r.porcentaje).reduce((a, b) => a > b ? a : b);
    final cerrada = _servicio.estaCerrada;
    final puedeVotar = !_yaVote && !cerrada;

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Vota Dolores Hidalgo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Reiniciar plebiscito',
            onPressed: _reiniciar,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                EncabezadoPlebiscito(
                  pregunta: _votacion.pregunta,
                  totalVotos: _servicio.totalVotos,
                  limiteVotantes: _votacion.limiteVotantes,
                  tiempoRestante:
                      _votacion.fechaCierre.difference(DateTime.now()),
                  cerrada: cerrada,
                  anonima: _votacion.anonima,
                ),
                const SizedBox(height: 18),
                _Aviso(
                  icono: _yaVote
                      ? Icons.check_circle_rounded
                      : Icons.touch_app_rounded,
                  texto: _yaVote
                      ? 'Tu voto quedó registrado. Es un voto secreto: '
                          'nadie sabrá por cuál opción votaste.'
                      : cerrada
                          ? 'La votación ya cerró. Aquí están los resultados finales.'
                          : 'Elige una opción para votar. Solo puedes votar una vez.',
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < resultados.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: BarraOpcion(
                      resultado: resultados[i],
                      indice: i,
                      esLider: maxPorcentaje > 0 &&
                          resultados[i].porcentaje == maxPorcentaje,
                      puedeVotar: puedeVotar,
                      onVotar: () => _votar(resultados[i].opcion.id),
                    ),
                  ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: _verGanador,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: const Text('Ver resultado del plebiscito'),
                ),
                const SizedBox(height: 22),
                _ModoDemostracion(
                  onNuevoVotante: _yaVote ? _nuevoVotante : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Aviso({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icono, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModoDemostracion extends StatelessWidget {
  final VoidCallback? onNuevoVotante;

  const _ModoDemostracion({required this.onNuevoVotante});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modo demostración',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Simula que otro vecino llega a votar desde este mismo dispositivo. '
            'Se habilita después de que votes.',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onNuevoVotante,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Nuevo votante'),
          ),
        ],
      ),
    );
  }
}
