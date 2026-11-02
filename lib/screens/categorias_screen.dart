import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../providers/categorias_provider.dart';
import '../repositories/categorias_repository.dart';
import 'categoria_form_screen.dart';

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  Future<void> _abrirFormulario(
    BuildContext context, {
    Categoria? categoria,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoriaFormScreen(categoria: categoria),
      ),
    );
  }

  Future<void> _cambiarArchivo(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final controller = ref.read(categoriasControllerProvider);

      if (categoria.archivada) {
        await controller.restaurar(categoria.id!);
      } else {
        await controller.archivar(categoria.id!);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            categoria.archivada
                ? 'Categoría restaurada.'
                : 'Categoría archivada.',
          ),
        ),
      );
    } on CategoriaException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la categoría.')),
      );
    }
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Deseas eliminar "${categoria.nombre}"? '
          'Esta operación no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(categoriasControllerProvider).eliminar(categoria.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría eliminada correctamente.')),
      );
    } on CategoriaException catch (error) {
      if (!context.mounted) return;

      final archivar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No se pudo eliminar'),
          content: Text(error.mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Archivar'),
            ),
          ],
        ),
      );

      if (archivar == true && context.mounted) {
        await _cambiarArchivo(context, ref, categoria);
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al eliminar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de gastos'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: categoriasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No se pudieron cargar las categorías.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(categoriasProvider);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    'Todavía no hay categorías registradas.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text('Presiona Nueva categoría para comenzar.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoriasProvider);
              await ref.read(categoriasProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: categoria.archivada
                          ? Colors.grey
                          : Colors.teal,
                      foregroundColor: Colors.white,
                      child: Icon(
                        categoria.archivada
                            ? Icons.archive_outlined
                            : Icons.category,
                      ),
                    ),
                    title: Text(
                      categoria.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${categoria.tipo} · '
                      '${categoria.archivada ? "Archivada" : "Activa"}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      onSelected: (opcion) async {
                        if (opcion == 'editar') {
                          await _abrirFormulario(context, categoria: categoria);
                        } else if (opcion == 'archivar') {
                          await _cambiarArchivo(context, ref, categoria);
                        } else if (opcion == 'eliminar') {
                          await _eliminar(context, ref, categoria);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'archivar',
                          child: Text(
                            categoria.archivada ? 'Restaurar' : 'Archivar',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _abrirFormulario(context, categoria: categoria),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
