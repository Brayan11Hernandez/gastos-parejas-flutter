import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';

// ======================================================
// ERRORES CONTROLADOS
// ======================================================

class CategoriaException implements Exception {
  final String mensaje;

  const CategoriaException(this.mensaje);

  @override
  String toString() => mensaje;
}

// ======================================================
// REPOSITORIO DE CATEGORÍAS - LABORATORIO S16
// ======================================================

class CategoriasRepository {
  // Permite utilizar una base temporal en las pruebas.
  // Si no se proporciona una ruta, se utiliza la base
  // de datos normal de la aplicación.
  final String? rutaBaseDatos;

  CategoriasRepository({this.rutaBaseDatos});

  Future<T> _usarBase<T>(Future<T> Function(Database db) operacion) async {
    final db = await AppDatabase.abrir(rutaPersonalizada: rutaBaseDatos);

    try {
      return await operacion(db);
    } finally {
      await db.close();
    }
  }

  // ====================================================
  // READ: CONSULTAR CATEGORÍAS
  // ====================================================

  Future<List<Categoria>> obtenerCategorias({
    bool incluirArchivadas = true,
  }) async {
    return _usarBase((db) async {
      final filas = await db.query(
        'categorias',
        where: incluirArchivadas ? null : 'archivada = ?',
        whereArgs: incluirArchivadas ? null : [0],
        orderBy: 'nombre COLLATE NOCASE ASC',
      );

      return filas.map(Categoria.fromMap).toList();
    });
  }

  // ====================================================
  // READ: BUSCAR POR ID
  // ====================================================

  Future<Categoria?> obtenerPorId(int id) async {
    return _usarBase((db) async {
      final filas = await db.query(
        'categorias',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (filas.isEmpty) {
        return null;
      }

      return Categoria.fromMap(filas.first);
    });
  }

  // ====================================================
  // VALIDACIÓN DE NOMBRES DUPLICADOS
  // ====================================================

  Future<bool> existeNombre(String nombre, {int? excluirId}) async {
    return _usarBase((db) async {
      return _nombreExiste(db, nombre.trim(), excluirId: excluirId);
    });
  }

  Future<bool> _nombreExiste(
    DatabaseExecutor db,
    String nombre, {
    int? excluirId,
  }) async {
    final filas = await db.query(
      'categorias',
      columns: ['id'],
      where: excluirId == null
          ? 'nombre = ? COLLATE NOCASE'
          : 'nombre = ? COLLATE NOCASE AND id != ?',
      whereArgs: excluirId == null ? [nombre] : [nombre, excluirId],
      limit: 1,
    );

    return filas.isNotEmpty;
  }

  void _validarNombre(String nombre) {
    if (nombre.trim().isEmpty) {
      throw const CategoriaException(
        'El nombre de la categoría es obligatorio.',
      );
    }
  }

  void _validarTipo(String tipo) {
    if (tipo != 'Gasto' && tipo != 'Ingreso') {
      throw const CategoriaException('El tipo debe ser Gasto o Ingreso.');
    }
  }

  // ====================================================
  // CREATE: CREAR CATEGORÍA
  // ====================================================

  Future<int> crearCategoria(Categoria categoria) async {
    final nombre = categoria.nombre.trim();

    _validarNombre(nombre);
    _validarTipo(categoria.tipo);

    return _usarBase((db) async {
      return db.transaction((txn) async {
        if (await _nombreExiste(txn, nombre)) {
          throw const CategoriaException(
            'Ya existe una categoría con ese nombre.',
          );
        }

        return txn.insert('categorias', {
          'nombre': nombre,
          'tipo': categoria.tipo,
          'archivada': categoria.archivada ? 1 : 0,
        });
      });
    });
  }

  // ====================================================
  // UPDATE: EDITAR SIN CAMBIAR EL ID
  // ====================================================

  Future<void> actualizarCategoria(Categoria categoria) async {
    final id = categoria.id;
    final nombre = categoria.nombre.trim();

    if (id == null) {
      throw const CategoriaException(
        'La categoría necesita un ID para editarse.',
      );
    }

    _validarNombre(nombre);
    _validarTipo(categoria.tipo);

    await _usarBase((db) async {
      await db.transaction((txn) async {
        final existe = await txn.query(
          'categorias',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (existe.isEmpty) {
          throw const CategoriaException('La categoría no existe.');
        }

        if (await _nombreExiste(txn, nombre, excluirId: id)) {
          throw const CategoriaException(
            'Ya existe otra categoría con ese nombre.',
          );
        }

        await txn.update(
          'categorias',
          {
            'nombre': nombre,
            'tipo': categoria.tipo,
            'archivada': categoria.archivada ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    });
  }

  // ====================================================
  // CONTAR GASTOS ASOCIADOS
  // ====================================================

  Future<int> contarGastosAsociados(int categoriaId) async {
    return _usarBase((db) async {
      final resultado = await db.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM gastos
        WHERE categoria_id = ?
        ''',
        [categoriaId],
      );

      return (resultado.first['total'] as num).toInt();
    });
  }

  // ====================================================
  // DELETE: ELIMINAR CATEGORÍA
  // ====================================================

  Future<void> eliminarCategoria(int id) async {
    await _usarBase((db) async {
      await db.transaction((txn) async {
        final existe = await txn.query(
          'categorias',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (existe.isEmpty) {
          throw const CategoriaException('La categoría no existe.');
        }

        final resultado = await txn.rawQuery(
          '''
          SELECT COUNT(*) AS total
          FROM gastos
          WHERE categoria_id = ?
          ''',
          [id],
        );

        final cantidad = (resultado.first['total'] as num).toInt();

        if (cantidad > 0) {
          throw CategoriaException(
            'No se puede eliminar esta categoría porque '
            'tiene $cantidad gasto(s) asociado(s). '
            'Puedes archivarla en su lugar.',
          );
        }

        await txn.delete('categorias', where: 'id = ?', whereArgs: [id]);
      });
    });
  }

  // ====================================================
  // ARCHIVAR CATEGORÍA
  // ====================================================

  Future<void> archivarCategoria(int id) async {
    await _cambiarEstadoArchivado(id, true);
  }

  // ====================================================
  // RESTAURAR CATEGORÍA
  // ====================================================

  Future<void> restaurarCategoria(int id) async {
    await _cambiarEstadoArchivado(id, false);
  }

  Future<void> _cambiarEstadoArchivado(int id, bool archivada) async {
    await _usarBase((db) async {
      final actualizados = await db.update(
        'categorias',
        {'archivada': archivada ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (actualizados == 0) {
        throw const CategoriaException('No se encontró la categoría.');
      }
    });
  }
}
