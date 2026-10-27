import '../models/gasto.dart';

class GastosRepository {
  Future<List<Gasto>> obtenerGastos() async {
    // Simulamos una consulta a una base de datos.
    await Future.delayed(const Duration(seconds: 2));

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
      Gasto(
        id: '4',
        nombre: 'Cine',
        categoria: 'Entretenimiento',
        monto: 90.00,
        fecha: DateTime(2026, 10, 23),
      ),
      Gasto(
        id: '5',
        nombre: 'Supermercado',
        categoria: 'Compras',
        monto: 285.50,
        fecha: DateTime(2026, 10, 22),
      ),
    ];
  }
}
