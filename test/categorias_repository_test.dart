import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:gastos_parejas/database/app_database.dart';
import 'package:gastos_parejas/models/categoria.dart';
import 'package:gastos_parejas/repositories/categorias_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory carpetaTemporal;
  late String rutaBase;
  late CategoriasRepository repository;

  setUp(() async {
    // Crear una base de datos temporal por prueba.
    carpetaTemporal = await Directory.systemTemp.createTemp('s16_categorias_');

    rutaBase = p.join(carpetaTemporal.path, 'categorias_test.db');

    repository = CategoriasRepository(rutaBaseDatos: rutaBase);
  });

  tearDown(() async {
    final factory = AppDatabase.obtenerFactory();

    await factory.deleteDatabase(rutaBase);

    if (await carpetaTemporal.exists()) {
      await carpetaTemporal.delete(recursive: true);
    }
  });

  // ==================================================
  // PRUEBA 1: CREAR Y CONSULTAR
  // ==================================================

  test('Crea y consulta una categoria', () async {
    final id = await repository.crearCategoria(
      const Categoria(nombre: 'Alimentacion', tipo: 'Gasto'),
    );

    final categoria = await repository.obtenerPorId(id);

    expect(categoria, isNotNull);
    expect(categoria!.id, id);
    expect(categoria.nombre, 'Alimentacion');
    expect(categoria.archivada, isFalse);
  });

  // ==================================================
  // PRUEBA 2: RECHAZAR NOMBRES DUPLICADOS
  // ==================================================

  test('Rechaza nombres duplicados', () async {
    await repository.crearCategoria(const Categoria(nombre: 'Transporte'));

    await expectLater(
      repository.crearCategoria(const Categoria(nombre: 'transporte')),
      throwsA(isA<CategoriaException>()),
    );

    final categorias = await repository.obtenerCategorias();

    expect(categorias.length, 1);
  });

  // ==================================================
  // PRUEBA 3: EDITAR Y CONSERVAR ID
  // ==================================================

  test('Edita categoria conservando el ID', () async {
    final id = await repository.crearCategoria(
      const Categoria(nombre: 'Comida'),
    );

    final original = await repository.obtenerPorId(id);

    await repository.actualizarCategoria(
      original!.copyWith(nombre: 'Comida y bebidas'),
    );

    final actualizada = await repository.obtenerPorId(id);

    expect(actualizada!.id, id);
    expect(actualizada.nombre, 'Comida y bebidas');
  });

  // ==================================================
  // PRUEBA 4: ARCHIVAR Y RESTAURAR
  // ==================================================

  test('Archiva y restaura una categoria', () async {
    final id = await repository.crearCategoria(
      const Categoria(nombre: 'Compras'),
    );

    await repository.archivarCategoria(id);

    var categoria = await repository.obtenerPorId(id);

    expect(categoria!.archivada, isTrue);

    final activas = await repository.obtenerCategorias(
      incluirArchivadas: false,
    );

    expect(activas, isEmpty);

    await repository.restaurarCategoria(id);

    categoria = await repository.obtenerPorId(id);

    expect(categoria!.archivada, isFalse);
  });

  // ==================================================
  // PRUEBA 5: PROTEGER CATEGORIAS CON GASTOS
  // ==================================================

  test('Impide eliminar una categoria con gastos asociados', () async {
    // Crear categoria.
    final id = await repository.crearCategoria(
      const Categoria(nombre: 'Transporte'),
    );

    // Insertar gasto asociado directamente en SQLite.
    final db = await AppDatabase.abrir(rutaPersonalizada: rutaBase);

    try {
      await db.insert('gastos', {
        'id': 'gasto-uber-001',
        'nombre': 'Uber',
        'categoria_id': id,
        'monto': 40.00,
        'fecha': '2026-10-25',
      });
    } finally {
      await db.close();
    }

    // Confirmar que la categoria tiene un gasto.
    expect(await repository.contarGastosAsociados(id), 1);

    // Intentar eliminar y esperar un rechazo.
    await expectLater(
      repository.eliminarCategoria(id),
      throwsA(
        isA<CategoriaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('gasto(s) asociado(s)'),
        ),
      ),
    );

    // Comprobar que la categoria sigue guardada.
    final categoria = await repository.obtenerPorId(id);

    expect(categoria, isNotNull);
    expect(categoria!.nombre, 'Transporte');

    // Comprobar que el gasto sigue guardado.
    final dbVerificacion = await AppDatabase.abrir(rutaPersonalizada: rutaBase);

    try {
      final gastos = await dbVerificacion.query(
        'gastos',
        where: 'categoria_id = ?',
        whereArgs: [id],
      );

      expect(gastos.length, 1);
      expect(gastos.first['nombre'], 'Uber');
    } finally {
      await dbVerificacion.close();
    }
  });

  // ==================================================
  // PRUEBA 6: ELIMINAR CATEGORIA SIN GASTOS
  // ==================================================

  test('Elimina categoria sin gastos', () async {
    final id = await repository.crearCategoria(
      const Categoria(nombre: 'Temporal'),
    );

    await repository.eliminarCategoria(id);

    final categoria = await repository.obtenerPorId(id);

    expect(categoria, isNull);
  });
}
