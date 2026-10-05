import 'opcion_votacion.dart';

class Votacion {
  final String pregunta;
  final List<OpcionVotacion> opciones;
  final DateTime fechaCierre;

  /// Reto 2: maximo de votantes distintos. null significa sin limite.
  final int? limiteVotantes;

  /// Reto 3: si es true solo se guarda que el usuario ya voto,
  /// nunca por cual opcion lo hizo.
  final bool anonima;

  final Set<String> votantes = {};

  /// idUsuario -> idOpcion. Solo se llena cuando la votacion NO es anonima.
  final Map<String, String> votosPorUsuario = {};

  Votacion({
    required this.pregunta,
    required this.opciones,
    required this.fechaCierre,
    this.limiteVotantes,
    this.anonima = false,
  });
}
