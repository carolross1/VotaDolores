import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/votacion.dart';

/// Reto 5: guarda y recupera el estado de la votacion en el dispositivo
/// para que los votos sobrevivan a cerrar la app.
class RepositorioVotacion {
  static const String _claveEstado = 'vota_dolores_estado_v1';
  static const String _claveUsuario = 'vota_dolores_usuario_v1';

  Future<void> guardar(Votacion votacion) async {
    final prefs = await SharedPreferences.getInstance();
    final estado = <String, dynamic>{
      'fechaCierre': votacion.fechaCierre.toIso8601String(),
      'votos': {for (final o in votacion.opciones) o.id: o.votos},
      'votantes': votacion.votantes.toList(),
      'votosPorUsuario': votacion.votosPorUsuario,
    };
    await prefs.setString(_claveEstado, jsonEncode(estado));
  }

  /// Fecha de cierre guardada, o null si todavia no hay nada guardado.
  Future<DateTime?> leerFechaCierre() async {
    final estado = await _leerEstado();
    final texto = estado?['fechaCierre'];
    return texto is String ? DateTime.tryParse(texto) : null;
  }

  /// Aplica sobre [votacion] los votos, votantes y votos por usuario guardados.
  /// Si no hay nada guardado, no cambia nada.
  Future<void> restaurar(Votacion votacion) async {
    final estado = await _leerEstado();
    if (estado == null) return;

    final votos = estado['votos'];
    if (votos is Map) {
      for (final o in votacion.opciones) {
        final valor = votos[o.id];
        if (valor is int) o.votos = valor;
      }
    }

    final votantes = estado['votantes'];
    if (votantes is List) {
      votacion.votantes.addAll(votantes.whereType<String>());
    }

    final porUsuario = estado['votosPorUsuario'];
    if (porUsuario is Map) {
      porUsuario.forEach((clave, valor) {
        if (clave is String && valor is String) {
          votacion.votosPorUsuario[clave] = valor;
        }
      });
    }
  }

  Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveEstado);
    await prefs.remove(_claveUsuario);
  }

  /// Id del votante de este dispositivo. Se crea una sola vez y se conserva.
  Future<String> leerOCrearIdUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final existente = prefs.getString(_claveUsuario);
    if (existente != null) return existente;

    final nuevo = 'invitado-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_claveUsuario, nuevo);
    return nuevo;
  }

  Future<void> guardarIdUsuario(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUsuario, id);
  }

  Future<Map<String, dynamic>?> _leerEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveEstado);
    if (texto == null) return null;
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is Map<String, dynamic> ? decodificado : null;
    } catch (_) {
      return null;
    }
  }
}
