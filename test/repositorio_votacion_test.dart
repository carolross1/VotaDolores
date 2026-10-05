import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vota_dolores_hidalgo/datos/repositorio_votacion.dart';
import 'package:vota_dolores_hidalgo/logica/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logica/servicio_votacion.dart';
import 'package:vota_dolores_hidalgo/modelos/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/modelos/votacion.dart';

Votacion _crearVotacion({bool anonima = false, DateTime? fechaCierre}) {
  return Votacion(
    pregunta: 'Pregunta de prueba',
    opciones: [
      OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
    ],
    fechaCierre: fechaCierre ?? DateTime.now().add(const Duration(days: 7)),
    anonima: anonima,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guardar y restaurar conserva votos y votantes', () async {
    final repo = RepositorioVotacion();
    final original = _crearVotacion();
    final servicio = ServicioVotacion(original);
    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op2');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op2');
    await repo.guardar(original);

    final recuperada = _crearVotacion();
    await repo.restaurar(recuperada);

    expect(recuperada.opciones[0].votos, 1);
    expect(recuperada.opciones[1].votos, 2);
    expect(recuperada.votantes, unorderedEquals(['u1', 'u2', 'u3']));
  });

  test('tras restaurar, quien ya voto sigue sin poder votar', () async {
    final repo = RepositorioVotacion();
    final original = _crearVotacion();
    ServicioVotacion(original).registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    await repo.guardar(original);

    final recuperada = _crearVotacion();
    await repo.restaurar(recuperada);
    final resultado = ServicioVotacion(recuperada)
        .registrarVoto(idUsuario: 'u1', idOpcion: 'op2');

    expect(resultado, ResultadoVoto.usuarioYaVoto);
    expect(recuperada.opciones[1].votos, 0);
  });

  test('restaurar sin nada guardado no cambia la votacion', () async {
    final repo = RepositorioVotacion();
    final votacion = _crearVotacion();

    await repo.restaurar(votacion);

    expect(votacion.opciones.every((o) => o.votos == 0), true);
    expect(votacion.votantes.isEmpty, true);
  });

  test('votacion no anonima restaura por que opcion voto cada usuario', () async {
    final repo = RepositorioVotacion();
    final original = _crearVotacion();
    ServicioVotacion(original).registrarVoto(idUsuario: 'u1', idOpcion: 'op2');
    await repo.guardar(original);

    final recuperada = _crearVotacion();
    await repo.restaurar(recuperada);

    expect(recuperada.votosPorUsuario['u1'], 'op2');
  });

  test('votacion anonima no guarda por que opcion voto cada usuario', () async {
    final repo = RepositorioVotacion();
    final original = _crearVotacion(anonima: true);
    ServicioVotacion(original).registrarVoto(idUsuario: 'u1', idOpcion: 'op2');
    await repo.guardar(original);

    final recuperada = _crearVotacion(anonima: true);
    await repo.restaurar(recuperada);

    expect(recuperada.votantes.contains('u1'), true);
    expect(recuperada.votosPorUsuario.isEmpty, true);
  });

  test('borrar elimina el estado guardado', () async {
    final repo = RepositorioVotacion();
    final original = _crearVotacion();
    ServicioVotacion(original).registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    await repo.guardar(original);

    await repo.borrar();

    final recuperada = _crearVotacion();
    await repo.restaurar(recuperada);
    expect(await repo.leerFechaCierre(), null);
    expect(recuperada.opciones[0].votos, 0);
  });

  test('leerFechaCierre regresa la fecha guardada', () async {
    final repo = RepositorioVotacion();
    final fecha = DateTime(2031, 5, 20, 18, 30);
    await repo.guardar(_crearVotacion(fechaCierre: fecha));

    expect(await repo.leerFechaCierre(), fecha);
  });

  test('el id de usuario se crea una vez y se conserva', () async {
    final repo = RepositorioVotacion();

    final primero = await repo.leerOCrearIdUsuario();
    final segundo = await repo.leerOCrearIdUsuario();
    expect(segundo, primero);

    await repo.guardarIdUsuario('vecino-especial');
    expect(await repo.leerOCrearIdUsuario(), 'vecino-especial');
  });
}
