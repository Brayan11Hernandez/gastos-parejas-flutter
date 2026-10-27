import 'package:flutter_riverpod/legacy.dart';

// Guarda los identificadores de los gastos eliminados.
final gastosEliminadosProvider = StateProvider<List<String>>((ref) => []);
