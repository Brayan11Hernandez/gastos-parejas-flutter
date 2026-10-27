import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gastos_parejas/main.dart';
import 'package:gastos_parejas/models/gasto.dart';
import 'package:gastos_parejas/providers/gastos_provider.dart';
import 'package:gastos_parejas/repositories/gastos_repository.dart';

// ===================================================
// REPOSITORIO FALSO PARA LAS PRUEBAS
// ===================================================

class FakeGastosRepository extends GastosRepository {
  FakeGastosRepository(this.cargarGastos);

  final Future<List<Gasto>> Function() cargarGastos;

  @override
  Future<List<Gasto>> obtenerGastos() {
    return cargarGastos();
  }
}

// ===================================================
// DATOS DE EJEMPLO PARA LAS PRUEBAS
// ===================================================

List<Gasto> gastosDePrueba() {
  return [
    Gasto(
      id: '1',
      nombre: 'Almuerzo',
      categoria: 'Alimentación',
      monto: 35.00,
      fecha: DateTime(2026, 10, 26),
    ),
    Gasto(
      id: '2',
      nombre: 'Uber',
      categoria: 'Transporte',
      monto: 40.00,
      fecha: DateTime(2026, 10, 25),
    ),
    Gasto(
      id: '3',
      nombre: 'Café',
      categoria: 'Alimentación',
      monto: 25.00,
      fecha: DateTime(2026, 10, 24),
    ),
  ];
}

// ===================================================
// FUNCIÓN PARA ABRIR EL HISTORIAL
// ===================================================

Future<void> abrirHistorial(
  WidgetTester tester,
  FakeGastosRepository repositorio,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [gastosRepositoryProvider.overrideWithValue(repositorio)],
      child: const GastosApp(),
    ),
  );

  // Verificar que aparece la pantalla de inicio.
  expect(find.text('Bienvenido a Gastos Parejas'), findsOneWidget);

  // Navegar al historial.
  await tester.tap(find.text('Ver historial de gastos'));

  // Esperar la navegación y la carga de datos.
  await tester.pumpAndSettle();
}

// ===================================================
// PRUEBAS AUTOMATIZADAS - LABORATORIO S15
// ===================================================

void main() {
  // -------------------------------------------------
  // PRUEBA 1: NAVEGACIÓN
  // -------------------------------------------------

  testWidgets('Navega correctamente al historial', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return gastosDePrueba();
    });

    await abrirHistorial(tester, repositorio);

    expect(find.text('Historial de gastos'), findsOneWidget);
  });

  // -------------------------------------------------
  // PRUEBA 2: MOSTRAR GASTOS
  // -------------------------------------------------

  testWidgets('Muestra los gastos correctamente', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return gastosDePrueba();
    });

    await abrirHistorial(tester, repositorio);

    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);

    expect(find.text('Q35.00'), findsOneWidget);
    expect(find.text('Q40.00'), findsOneWidget);
    expect(find.text('Q25.00'), findsOneWidget);
  });

  // -------------------------------------------------
  // PRUEBA 3: ESTADO DE ERROR
  // -------------------------------------------------

  testWidgets('Muestra error y botón Reintentar', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      throw Exception('Error de conexión');
    });

    await abrirHistorial(tester, repositorio);

    expect(find.text('Ocurrió un error al cargar los gastos'), findsOneWidget);

    expect(find.text('Reintentar'), findsOneWidget);
  });

  // -------------------------------------------------
  // PRUEBA 4: LISTA VACÍA
  // -------------------------------------------------

  testWidgets('Muestra mensaje cuando no hay gastos', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return [];
    });

    await abrirHistorial(tester, repositorio);

    expect(find.text('Todavía no hay gastos registrados'), findsOneWidget);

    expect(find.text('Actualizar'), findsOneWidget);
  });

  // -------------------------------------------------
  // PRUEBA 5: FILTROS POR CATEGORÍA
  // -------------------------------------------------

  testWidgets('Filtra gastos por categoría', (tester) async {
    final repositorio = FakeGastosRepository(() async {
      return gastosDePrueba();
    });

    await abrirHistorial(tester, repositorio);

    // Inicialmente aparecen todos los gastos.
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);

    // Abrir selector de categorías.
    await tester.tap(find.text('Todas'));

    await tester.pumpAndSettle();

    // Seleccionar Alimentación.
    await tester.tap(find.text('Alimentación').last);

    await tester.pumpAndSettle();

    // Verificar resultados.
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);

    // Uber no debe aparecer.
    expect(find.text('Uber'), findsNothing);
  });

  // -------------------------------------------------
  // PRUEBA 6: ELIMINAR Y DESHACER
  // -------------------------------------------------

  testWidgets('Elimina un gasto y permite deshacer', (tester) async {
    // AMPLIAR LA VENTANA SIMULADA.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;

    // RESTAURAR EL TAMAÑO AL TERMINAR LA PRUEBA.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repositorio = FakeGastosRepository(() async {
      return gastosDePrueba();
    });

    await abrirHistorial(tester, repositorio);

    // Verificar que Almuerzo existe.
    expect(find.text('Almuerzo'), findsOneWidget);

    // DESLIZAR EL GASTO HACIA LA IZQUIERDA.
    await tester.drag(find.text('Almuerzo'), const Offset(-700, 0));

    // Iniciar la animación.
    await tester.pump();

    // Esperar a que aparezca el SnackBar.
    // Evitamos pumpAndSettle porque podría hacer
    // que desaparezca el botón antes de presionarlo.
    for (int intento = 0; intento < 20; intento++) {
      await tester.pump(const Duration(milliseconds: 100));

      if (find.text('DESHACER').evaluate().isNotEmpty) {
        break;
      }
    }

    // Verificar que el gasto desapareció.
    expect(find.text('Almuerzo'), findsNothing);

    // Verificar la notificación.
    expect(find.text('Almuerzo eliminado'), findsOneWidget);

    // Verificar que existe el botón DESHACER.
    expect(find.text('DESHACER'), findsOneWidget);

    // Asegurar que el botón termine de aparecer.
    await tester.pump(const Duration(milliseconds: 300));

    // PRESIONAR DESHACER.
    await tester.tap(find.text('DESHACER'));

    // Esperar a que se actualice el historial.
    await tester.pumpAndSettle();

    // Verificar que Almuerzo volvió a aparecer.
    expect(find.text('Almuerzo'), findsOneWidget);
  });
}
