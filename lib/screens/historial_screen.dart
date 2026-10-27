import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gastos_provider.dart';
import '../providers/filtros_provider.dart';
import '../providers/eliminados_provider.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastosAsync = ref.watch(gastosProvider);

    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);

    final gastosEliminados = ref.watch(gastosEliminadosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de gastos'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: gastosAsync.when(
        // ESTADO: CARGANDO
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando gastos...'),
            ],
          ),
        ),

        // ESTADO: ERROR
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 70, color: Colors.red),
              SizedBox(height: 15),
              Text(
                'Ocurrió un error al cargar los gastos',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(gastosProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),

        // ESTADO: DATOS
        data: (gastos) {
          if (gastos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  const Text('Todavía no hay gastos registrados'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(gastosProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
            );
          }

          // FILTRAR LOS GASTOS NO ELIMINADOS
          final gastosVisibles = gastos.where((gasto) {
            final noEliminado = !gastosEliminados.contains(gasto.id);

            final coincideCategoria =
                categoriaSeleccionada == 'Todas' ||
                gasto.categoria == categoriaSeleccionada;

            return noEliminado && coincideCategoria;
          }).toList();

          return Column(
            children: [
              // FILTRO POR CATEGORÍA
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoría',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                    DropdownMenuItem(
                      value: 'Alimentación',
                      child: Text('Alimentación'),
                    ),
                    DropdownMenuItem(
                      value: 'Transporte',
                      child: Text('Transporte'),
                    ),
                    DropdownMenuItem(
                      value: 'Entretenimiento',
                      child: Text('Entretenimiento'),
                    ),
                    DropdownMenuItem(value: 'Compras', child: Text('Compras')),
                  ],
                  onChanged: (categoria) {
                    if (categoria != null) {
                      ref.read(categoriaSeleccionadaProvider.notifier).state =
                          categoria;
                    }
                  },
                ),
              ),

              // LISTADO DE GASTOS
              Expanded(
                child: gastosVisibles.isEmpty
                    ? const Center(
                        child: Text('No hay gastos en esta categoría'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: gastosVisibles.length,
                        itemBuilder: (context, index) {
                          final gasto = gastosVisibles[index];

                          return Dismissible(
                            key: ValueKey(gasto.id),

                            // DESLIZAR EN AMBAS DIRECCIONES
                            direction: DismissDirection.horizontal,

                            // FONDO AL DESLIZAR
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),

                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),

                            // ELIMINAR EL GASTO
                            onDismissed: (direction) {
                              final eliminadosActuales = ref.read(
                                gastosEliminadosProvider,
                              );

                              ref
                                  .read(gastosEliminadosProvider.notifier)
                                  .state = [
                                ...eliminadosActuales,
                                gasto.id,
                              ];

                              final messenger = ScaffoldMessenger.of(context);

                              messenger.hideCurrentSnackBar();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${gasto.nombre} eliminado'),
                                  duration: const Duration(seconds: 5),
                                  action: SnackBarAction(
                                    label: 'DESHACER',
                                    onPressed: () {
                                      final eliminados = ref.read(
                                        gastosEliminadosProvider,
                                      );

                                      ref
                                          .read(
                                            gastosEliminadosProvider.notifier,
                                          )
                                          .state = eliminados
                                          .where((id) => id != gasto.id)
                                          .toList();
                                    },
                                  ),
                                ),
                              );
                            },

                            // TARJETA DEL GASTO
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Icon(
                                    Icons.payments,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  gasto.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${gasto.categoria}\n'
                                  '${gasto.fecha.day}/'
                                  '${gasto.fecha.month}/'
                                  '${gasto.fecha.year}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  'Q${gasto.monto.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
