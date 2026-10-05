import 'package:flutter_test/flutter_test.dart';
import 'package:vota_dolores_hidalgo/modelos/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/modelos/votacion.dart';
import 'package:vota_dolores_hidalgo/logica/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logica/servicio_votacion.dart';

Votacion _crearVotacionDePrueba({
  DateTime? fechaCierre,
  int? limiteVotantes,
  bool anonima = false,
}) {
  return Votacion(
    pregunta: 'Pregunta de prueba',
    opciones: [
      OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
    ],
    fechaCierre: fechaCierre ?? DateTime.now().add(const Duration(days: 7)),
    limiteVotantes: limiteVotantes,
    anonima: anonima,
  );
}

void main() {
  // ---------------------------------------------------------------
  // RONDAS 1 A 8 DEL MANUAL
  // ---------------------------------------------------------------

  // RONDA 1
  test('registrar un voto valido incrementa el contador de esa opcion', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.exitoso);
    expect(votacion.opciones[0].votos, 1);
  });

  // RONDA 2
  test('votar por una opcion que no existe regresa opcionInvalida', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado =
        servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'no-existe');

    expect(resultado, ResultadoVoto.opcionInvalida);
  });

  // RONDA 3
  test('un mismo usuario no puede votar dos veces', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    final segundoIntento =
        servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2');

    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[1].votos, 0); // op2 no debio incrementarse
  });

  // RONDA 4
  test('calcula el porcentaje de cada opcion correctamente', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u4', idOpcion: 'op2');

    final resultados = servicio.obtenerResultados();
    final op1 = resultados.firstWhere((r) => r.opcion.id == 'op1');
    final op2 = resultados.firstWhere((r) => r.opcion.id == 'op2');

    expect(op1.porcentaje, 75.0);
    expect(op2.porcentaje, 25.0);
  });

  test('si no hay ningun voto, todos los porcentajes son 0', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultados = servicio.obtenerResultados();

    expect(resultados.every((r) => r.porcentaje == 0), true);
  });

  // RONDA 5
  test('determinarGanador regresa la opcion con mas votos', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op2');

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 1);
    expect(ganadores.first.id, 'op1');
  });

  // RONDA 6
  test('si hay empate, determinarGanador regresa mas de una opcion', () {
    final votacion = Votacion(
      pregunta: 'Pregunta de prueba',
      opciones: [
        OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
        OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
        OpcionVotacion(id: 'op3', texto: 'Opcion 3'),
      ],
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op2');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op3');

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 3);
  });

  // RONDA 7
  test('no se puede votar si la votacion ya cerro', () {
    final votacionCerrada = _crearVotacionDePrueba(
      fechaCierre: DateTime(2000, 1, 1), // una fecha muy en el pasado
    );
    final servicio = ServicioVotacion(votacionCerrada);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.votacionCerrada);
    expect(votacionCerrada.opciones[0].votos, 0);
  });

  test('si la votacion sigue abierta, el voto se registra normalmente', () {
    final votacionAbierta = _crearVotacionDePrueba(
      fechaCierre: DateTime.now().add(const Duration(days: 1)),
    );
    final servicio = ServicioVotacion(votacionAbierta);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.exitoso);
  });

  // INTEGRACION
  test('simulacion completa: varios vecinos votan y se determina un ganador', () {
    final votacion = Votacion(
      pregunta: 'Que obra prioritaria debe realizar el municipio?',
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitacion del Jardin Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: 'alumbrado', texto: 'Alumbrado en el Barrio de Analco'),
      ],
      fechaCierre: DateTime.now().add(const Duration(days: 3)),
    );
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: 'vecino1', idOpcion: 'jardin');
    servicio.registrarVoto(idUsuario: 'vecino2', idOpcion: 'jardin');
    servicio.registrarVoto(idUsuario: 'vecino3', idOpcion: 'biblioteca');
    servicio.registrarVoto(idUsuario: 'vecino1', idOpcion: 'alumbrado'); // repetido

    final resultados = servicio.obtenerResultados();
    final totalVotos = resultados.fold<int>(0, (s, r) => s + r.opcion.votos);
    final ganadores = servicio.determinarGanador();

    expect(totalVotos, 3);
    expect(ganadores.length, 1);
    expect(ganadores.first.id, 'jardin');
  });

  // MUCHOS VOTANTES
  test('muchos votantes: los porcentajes suman 100 y el voto repetido no cuenta', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    for (var i = 0; i < 10; i++) {
      servicio.registrarVoto(
        idUsuario: 'u$i',
        idOpcion: i < 7 ? 'op1' : 'op2', // 7 para op1, 3 para op2
      );
    }
    // intentos repetidos: ninguno debe contar
    for (var i = 0; i < 10; i++) {
      servicio.registrarVoto(idUsuario: 'u$i', idOpcion: 'op2');
    }

    final resultados = servicio.obtenerResultados();
    final suma = resultados.fold<double>(0, (s, r) => s + r.porcentaje);

    expect(votacion.votantes.length, 10);
    expect(resultados[0].porcentaje, 70.0);
    expect(resultados[1].porcentaje, 30.0);
    expect(suma, 100.0);
  });

  // ---------------------------------------------------------------
  // SECCION 8: RETOS DE EXTENSION
  // ---------------------------------------------------------------

  group('Reto 1 - reloj inyectado', () {
    test('el cierre depende del reloj inyectado y no de la fecha real', () {
      var ahora = DateTime(2030, 1, 1, 10, 0);
      final votacion = _crearVotacionDePrueba(
        fechaCierre: DateTime(2030, 1, 1, 12, 0),
      );
      final servicio = ServicioVotacion(votacion, reloj: () => ahora);

      final antes = servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');

      ahora = DateTime(2030, 1, 1, 12, 0, 1); // un segundo despues del cierre
      final despues = servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op1');

      expect(antes, ResultadoVoto.exitoso);
      expect(despues, ResultadoVoto.votacionCerrada);
      expect(votacion.opciones[0].votos, 1);
    });

    test('estaCerrada refleja el reloj inyectado', () {
      var ahora = DateTime(2030, 1, 1, 10, 0);
      final votacion = _crearVotacionDePrueba(
        fechaCierre: DateTime(2030, 1, 1, 12, 0),
      );
      final servicio = ServicioVotacion(votacion, reloj: () => ahora);

      expect(servicio.estaCerrada, false);

      ahora = DateTime(2030, 1, 1, 13, 0);

      expect(servicio.estaCerrada, true);
    });
  });

  group('Reto 2 - limite de votantes', () {
    test('el voto numero N+1 se rechaza con limiteAlcanzado', () {
      final votacion = _crearVotacionDePrueba(limiteVotantes: 3);
      final servicio = ServicioVotacion(votacion);

      for (var i = 1; i <= 3; i++) {
        final r = servicio.registrarVoto(idUsuario: 'u$i', idOpcion: 'op1');
        expect(r, ResultadoVoto.exitoso);
      }
      final rechazado = servicio.registrarVoto(idUsuario: 'u4', idOpcion: 'op1');

      expect(rechazado, ResultadoVoto.limiteAlcanzado);
      expect(votacion.opciones[0].votos, 3);
      expect(votacion.votantes.length, 3);
    });

    test('sin limite configurado no hay tope de votantes', () {
      final votacion = _crearVotacionDePrueba();
      final servicio = ServicioVotacion(votacion);

      for (var i = 0; i < 600; i++) {
        servicio.registrarVoto(idUsuario: 'u$i', idOpcion: 'op1');
      }

      expect(votacion.votantes.length, 600);
    });

    test('un voto repetido se reporta como usuarioYaVoto aunque el limite este lleno', () {
      final votacion = _crearVotacionDePrueba(limiteVotantes: 1);
      final servicio = ServicioVotacion(votacion);

      servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
      final repetido = servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op2');

      expect(repetido, ResultadoVoto.usuarioYaVoto);
    });
  });

  group('Reto 3 - votacion anonima', () {
    test('en modo anonimo solo se guarda que el usuario ya voto', () {
      final votacion = _crearVotacionDePrueba(anonima: true);
      final servicio = ServicioVotacion(votacion);

      servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');

      expect(votacion.votantes.contains('u1'), true);
      expect(votacion.votosPorUsuario.isEmpty, true);
      expect(votacion.opciones[0].votos, 1);
    });

    test('en modo anonimo el usuario tampoco puede votar dos veces', () {
      final votacion = _crearVotacionDePrueba(anonima: true);
      final servicio = ServicioVotacion(votacion);

      servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
      final repetido = servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op2');

      expect(repetido, ResultadoVoto.usuarioYaVoto);
      expect(votacion.opciones[1].votos, 0);
    });

    test('en modo no anonimo si se guarda por cual opcion voto cada usuario', () {
      final votacion = _crearVotacionDePrueba();
      final servicio = ServicioVotacion(votacion);

      servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op2');

      expect(votacion.votosPorUsuario['u1'], 'op2');
    });
  });

  group('Extras de ServicioVotacion', () {
    test('totalVotos suma los votos de todas las opciones', () {
      final votacion = _crearVotacionDePrueba();
      final servicio = ServicioVotacion(votacion);

      servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
      servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op2');
      servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op2');

      expect(servicio.totalVotos, 3);
    });

    test('sin votos, todas las opciones empatan en cero', () {
      final votacion = _crearVotacionDePrueba();
      final servicio = ServicioVotacion(votacion);

      expect(servicio.determinarGanador().length, 2);
    });
  });
}
