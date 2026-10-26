import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gasto.dart';
import '../repositories/gastos_repository.dart';

// Provider que permite acceder al repositorio de gastos.
final gastosRepositoryProvider = Provider<GastosRepository>((ref) {
  return GastosRepository();
});

// Provider que consulta los gastos de forma asíncrona.
final gastosProvider = FutureProvider<List<Gasto>>((ref) async {
  final repository = ref.watch(gastosRepositoryProvider);

  return repository.obtenerGastos();
});
