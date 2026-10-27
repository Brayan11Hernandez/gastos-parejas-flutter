import 'package:flutter_riverpod/legacy.dart';

// Categoría seleccionada por el usuario.
final categoriaSeleccionadaProvider = StateProvider<String>((ref) => 'Todas');
