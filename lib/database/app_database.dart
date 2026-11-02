import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static const int versionActual = 2;
  static const String nombreArchivo = 'gastos_parejas.db';

  static bool _ffiInicializado = false;

  // ==================================================
  // CONFIGURACIÓN DE SQLITE
  // ==================================================

  static DatabaseFactory obtenerFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      if (!_ffiInicializado) {
        sqfliteFfiInit();
        _ffiInicializado = true;
      }

      return databaseFactoryFfi;
    }

    return databaseFactory;
  }

  // ==================================================
  // RUTA PERMANENTE DE LA BASE DE DATOS
  // ==================================================

  static Future<String> obtenerRuta() async {
    final directorio = await getApplicationSupportDirectory();

    final carpeta = Directory(p.join(directorio.path, 'databases'));

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    return p.join(carpeta.path, nombreArchivo);
  }

  // ==================================================
  // ABRIR BASE DE DATOS Y APLICAR MIGRACIONES
  // ==================================================

  static Future<Database> abrir({
    String? rutaPersonalizada,
    int version = versionActual,
  }) async {
    final factory = obtenerFactory();
    final ruta = rutaPersonalizada ?? await obtenerRuta();

    return factory.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, nuevaVersion) async {
          await _crearVersion1(db);

          if (nuevaVersion >= 2) {
            await _migrarAVersion2(db);
          }
        },
        onUpgrade: (db, versionAnterior, nuevaVersion) async {
          if (versionAnterior < 2 && nuevaVersion >= 2) {
            await _migrarAVersion2(db);
          }
        },
      ),
    );
  }

  // ==================================================
  // VERSIÓN 1
  // ==================================================

  static Future<void> _crearVersion1(Database db) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
        tipo TEXT NOT NULL DEFAULT 'Gasto'
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria_id INTEGER,
        monto REAL NOT NULL CHECK (monto >= 0),
        fecha TEXT NOT NULL,
        FOREIGN KEY (categoria_id)
          REFERENCES categorias(id)
          ON DELETE RESTRICT
      )
    ''');
  }

  // ==================================================
  // MIGRACIÓN V1 A V2
  // ==================================================

  static Future<void> _migrarAVersion2(Database db) async {
    await db.execute('''
      ALTER TABLE categorias
      ADD COLUMN archivada INTEGER NOT NULL
      DEFAULT 0 CHECK (archivada IN (0, 1))
    ''');
  }

  // ==================================================
  // CONSULTAR LA VERSIÓN MEDIANTE SQLITE
  // ==================================================

  static Future<int> obtenerVersion(Database db) async {
    final resultado = await db.rawQuery('PRAGMA user_version');

    return (resultado.first['user_version'] as num).toInt();
  }

  static Future<int> consultarVersion() async {
    final db = await abrir();

    try {
      return await obtenerVersion(db);
    } finally {
      await db.close();
    }
  }
}
