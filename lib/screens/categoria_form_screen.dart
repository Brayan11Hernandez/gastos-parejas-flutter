import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../providers/categorias_provider.dart';
import '../repositories/categorias_repository.dart';

class CategoriaFormScreen extends ConsumerStatefulWidget {
  final Categoria? categoria;

  const CategoriaFormScreen({super.key, this.categoria});

  @override
  ConsumerState<CategoriaFormScreen> createState() =>
      _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends ConsumerState<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  String _tipo = 'Gasto';
  bool _guardando = false;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();

    final categoria = widget.categoria;

    if (categoria != null) {
      _nombreController.text = categoria.nombre;
      _tipo = categoria.tipo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _guardando = true);

    final nombre = _nombreController.text.trim();

    try {
      final controller = ref.read(categoriasControllerProvider);

      final duplicado = await controller.existeNombre(
        nombre,
        excluirId: widget.categoria?.id,
      );

      if (duplicado) {
        throw const CategoriaException(
          'Ya existe una categoría con ese nombre.',
        );
      }

      if (_esEdicion) {
        final actualizada = widget.categoria!.copyWith(
          nombre: nombre,
          tipo: _tipo,
        );

        await controller.actualizar(actualizada);
      } else {
        await controller.crear(Categoria(nombre: nombre, tipo: _tipo));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Categoría actualizada correctamente.'
                : 'Categoría creada correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } on CategoriaException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la categoría.')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar categoría' : 'Nueva categoría'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.category_outlined, size: 70, color: Colors.teal),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nombreController,
              enabled: !_guardando,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ejemplo: Alimentación',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Ingresa el nombre de la categoría.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de categoría',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
              ],
              onChanged: _guardando
                  ? null
                  : (valor) {
                      if (valor != null) {
                        setState(() => _tipo = valor);
                      }
                    },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _guardando
                    ? 'Guardando...'
                    : _esEdicion
                    ? 'Guardar cambios'
                    : 'Crear categoría',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
