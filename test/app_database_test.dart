import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:gastos_parejas/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory carpetaTemporal;
  late String rutaBaseDatos;

  setUp(() async {
    carpetaTemporal = await Directory.systemTemp.createTemp(
      'gastos_parejas_migracion_',
    );

    rutaBaseDatos = p.join(carpetaTemporal.path, 'prueba_migracion.db');
  });

  tearDown(() async {
    final factory = AppDatabase.obtenerFactory();

    await factory.deleteDatabase(rutaBaseDatos);

    if (await carpetaTemporal.exists()) {
      await carpetaTemporal.delete(recursive: true);
    }
  });

  test('Migra SQLite de version 1 a version 2 sin perder datos', () async {
    // ================================================
    // PASO 1: CREAR BASE DE DATOS VERSION 1
    // ================================================

    final dbV1 = await AppDatabase.abrir(
      rutaPersonalizada: rutaBaseDatos,
      version: 1,
    );

    expect(await AppDatabase.obtenerVersion(dbV1), 1);

    // ================================================
    // PASO 2: INSERTAR DATOS EN VERSION 1
    // ================================================

    final categoriaId = await dbV1.insert('categorias', {
      'nombre': 'Alimentacion',
      'tipo': 'Gasto',
    });

    await dbV1.insert('gastos', {
      'id': 'gasto-prueba-001',
      'nombre': 'Almuerzo',
      'categoria_id': categoriaId,
      'monto': 35.00,
      'fecha': '2026-10-26',
    });

    final categoriasAntes = await dbV1.query('categorias');
    final gastosAntes = await dbV1.query('gastos');

    expect(categoriasAntes.length, 1);
    expect(gastosAntes.length, 1);

    await dbV1.close();

    // ================================================
    // PASO 3: MIGRAR A VERSION 2
    // ================================================

    final dbV2 = await AppDatabase.abrir(
      rutaPersonalizada: rutaBaseDatos,
      version: 2,
    );

    try {
      expect(await AppDatabase.obtenerVersion(dbV2), 2);

      // ==============================================
      // PASO 4: COMPROBAR DATOS CONSERVADOS
      // ==============================================

      final categoriasDespues = await dbV2.query('categorias');

      final gastosDespues = await dbV2.query('gastos');

      expect(categoriasDespues.length, 1);
      expect(gastosDespues.length, 1);

      expect(categoriasDespues.first['id'], categoriaId);

      expect(categoriasDespues.first['nombre'], 'Alimentacion');

      expect(categoriasDespues.first['tipo'], 'Gasto');

      expect(categoriasDespues.first['archivada'], 0);

      expect(gastosDespues.first['id'], 'gasto-prueba-001');

      expect(gastosDespues.first['nombre'], 'Almuerzo');

      expect(gastosDespues.first['monto'], 35.00);

      expect(gastosDespues.first['categoria_id'], categoriaId);

      // ==============================================
      // PASO 5: VERIFICAR EL NUEVO CAMPO ARCHIVADA
      // ==============================================

      await dbV2.update(
        'categorias',
        {'archivada': 1},
        where: 'id = ?',
        whereArgs: [categoriaId],
      );

      final categoriaArchivada = await dbV2.query(
        'categorias',
        where: 'id = ?',
        whereArgs: [categoriaId],
      );

      expect(categoriaArchivada.first['archivada'], 1);

      // ==============================================
      // PASO 6: VERIFICAR INTEGRIDAD SQLITE
      // ==============================================

      final integridad = await dbV2.rawQuery('PRAGMA integrity_check');

      expect(integridad.first.values.first, 'ok');

      final clavesForaneas = await dbV2.rawQuery('PRAGMA foreign_key_check');

      expect(clavesForaneas, isEmpty);
    } finally {
      await dbV2.close();
    }
  });
}
