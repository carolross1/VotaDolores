import '../modelos/opcion_votacion.dart';
import '../modelos/resultado_opcion.dart';
import '../modelos/votacion.dart';
import 'resultado_voto.dart';

class ServicioVotacion {
  final Votacion votacion;
  final DateTime Function() _ahora;

  /// [reloj] permite inyectar la hora actual (Reto 1).
  /// Por defecto se usa la hora real del sistema.
  ServicioVotacion(this.votacion, {DateTime Function()? reloj})
      : _ahora = reloj ?? DateTime.now;

  bool get estaCerrada => _ahora().isAfter(votacion.fechaCierre);

  int get totalVotos =>
      votacion.opciones.fold<int>(0, (suma, o) => suma + o.votos);

  ResultadoVoto registrarVoto({
    required String idUsuario,
    required String idOpcion,
  }) {
    if (estaCerrada) return ResultadoVoto.votacionCerrada;

    final yaVoto = votacion.votantes.contains(idUsuario);
    if (yaVoto) return ResultadoVoto.usuarioYaVoto;

    final limite = votacion.limiteVotantes;
    final estaLlena = limite != null && votacion.votantes.length >= limite;
    if (estaLlena) return ResultadoVoto.limiteAlcanzado;

    final opcion = _buscarOpcion(idOpcion);
    if (opcion == null) return ResultadoVoto.opcionInvalida;

    opcion.votos++;
    votacion.votantes.add(idUsuario);
    if (!votacion.anonima) {
      votacion.votosPorUsuario[idUsuario] = idOpcion;
    }
    return ResultadoVoto.exitoso;
  }

  List<ResultadoOpcion> obtenerResultados() {
    final total = totalVotos;
    return votacion.opciones.map((o) {
      final porcentaje = total == 0 ? 0.0 : (o.votos / total) * 100;
      return ResultadoOpcion(o, porcentaje);
    }).toList();
  }

  List<OpcionVotacion> determinarGanador() {
    final maxVotos =
        votacion.opciones.map((o) => o.votos).reduce((a, b) => a > b ? a : b);
    return votacion.opciones.where((o) => o.votos == maxVotos).toList();
  }

  OpcionVotacion? _buscarOpcion(String id) {
    for (final o in votacion.opciones) {
      if (o.id == id) return o;
    }
    return null;
  }
}
