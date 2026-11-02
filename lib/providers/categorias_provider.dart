import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../repositories/categorias_repository.dart';

// =====================================================
// REPOSITORIO DE CATEGORÍAS
// =====================================================

final categoriasRepositoryProvider = Provider<CategoriasRepository>((ref) {
  return CategoriasRepository();
});

// =====================================================
// LISTADO DE CATEGORÍAS
// =====================================================

final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final repository = ref.watch(categoriasRepositoryProvider);

  return repository.obtenerCategorias();
});

// =====================================================
// LISTADO DE CATEGORÍAS ACTIVAS
// =====================================================

final categoriasActivasProvider = FutureProvider<List<Categoria>>((ref) async {
  final repository = ref.watch(categoriasRepositoryProvider);

  // Dependemos del listado general para actualizar
  // automáticamente cuando una categoría cambie.
  ref.watch(categoriasProvider);

  return repository.obtenerCategorias(incluirArchivadas: false);
});

// =====================================================
// OPERACIONES CRUD
// =====================================================

class CategoriasController {
  final Ref ref;

  CategoriasController(this.ref);

  // CREATE: crear categoría.
  Future<int> crear(Categoria categoria) async {
    final repository = ref.read(categoriasRepositoryProvider);

    final id = await repository.crearCategoria(categoria);

    _actualizarListados();

    return id;
  }

  // UPDATE: editar categoría.
  Future<void> actualizar(Categoria categoria) async {
    final repository = ref.read(categoriasRepositoryProvider);

    await repository.actualizarCategoria(categoria);

    _actualizarListados();
  }

  // DELETE: eliminar categoría.
  Future<void> eliminar(int id) async {
    final repository = ref.read(categoriasRepositoryProvider);

    await repository.eliminarCategoria(id);

    _actualizarListados();
  }

  // ARCHIVAR: ocultar categoría del listado activo.
  Future<void> archivar(int id) async {
    final repository = ref.read(categoriasRepositoryProvider);

    await repository.archivarCategoria(id);

    _actualizarListados();
  }

  // RESTAURAR: activar categoría archivada.
  Future<void> restaurar(int id) async {
    final repository = ref.read(categoriasRepositoryProvider);

    await repository.restaurarCategoria(id);

    _actualizarListados();
  }

  // Validar nombres duplicados.
  Future<bool> existeNombre(String nombre, {int? excluirId}) async {
    final repository = ref.read(categoriasRepositoryProvider);

    return repository.existeNombre(nombre, excluirId: excluirId);
  }

  // Recargar las categorías cuando haya cambios.
  void _actualizarListados() {
    ref.invalidate(categoriasProvider);
    ref.invalidate(categoriasActivasProvider);
  }
}

// =====================================================
// PROVIDER DEL CONTROLADOR
// =====================================================

final categoriasControllerProvider = Provider<CategoriasController>((ref) {
  return CategoriasController(ref);
});
