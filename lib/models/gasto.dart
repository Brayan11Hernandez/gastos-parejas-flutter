class Gasto {
  final String id;
  final String nombre;
  final String categoria;
  final double monto;
  final DateTime fecha;

  const Gasto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.monto,
    required this.fecha,
  });
}
