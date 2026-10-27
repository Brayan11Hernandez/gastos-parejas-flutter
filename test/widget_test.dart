import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gastos_parejas/main.dart';
import 'package:gastos_parejas/models/gasto.dart';
import 'package:gastos_parejas/providers/gastos_provider.dart';
import 'package:gastos_parejas/repositories/gastos_repository.dart';

class FakeGastosRepository extends GastosRepository {
  FakeGastosRepository(this.cargarGastos);

  final Future<List<Gasto>> Function() cargarGastos;

  @override
  Future<List<Gasto>> obtenerGastos() {
    return cargarGastos();
  }
}

void main() {
  testWidgets('Muestra los gastos correctamente', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return [
        Gasto(
          id: '1',
          nombre: 'Almuerzo',
          categoria: 'Alimentación',
          monto: 35.00,
          fecha: DateTime(2026, 10, 26),
        ),
      ];
    });

    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [gastosRepositoryProvider.overrideWithValue(repositorio)],
        child: const GastosApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Historial de gastos'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Q35.00'), findsOneWidget);
  });

  testWidgets('Muestra error y botón Reintentar', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      throw Exception('Error de conexión');
    });

    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [gastosRepositoryProvider.overrideWithValue(repositorio)],
        child: const GastosApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ocurrió un error al cargar los gastos'), findsOneWidget);

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Muestra mensaje cuando no hay gastos', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return [];
    });

    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [gastosRepositoryProvider.overrideWithValue(repositorio)],
        child: const GastosApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay gastos registrados'), findsOneWidget);

    expect(find.text('Actualizar'), findsOneWidget);
  });
}
