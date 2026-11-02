class Categoria {
  final int? id;
  final String nombre;
  final String tipo;
  final bool archivada;

  const Categoria({
    this.id,
    required this.nombre,
    this.tipo = 'Gasto',
    this.archivada = false,
  });

  // Convertir una fila de SQLite en una categoría.
  factory Categoria.fromMap(Map<String, Object?> mapa) {
    return Categoria(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      tipo: mapa['tipo'] as String? ?? 'Gasto',
      archivada: (mapa['archivada'] as int? ?? 0) == 1,
    );
  }

  // Convertir la categoría en datos para SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre.trim(),
      'tipo': tipo,
      'archivada': archivada ? 1 : 0,
    };
  }

  // Crear una copia con cambios sin perder el ID.
  Categoria copyWith({String? nombre, String? tipo, bool? archivada}) {
    return Categoria(
      id: id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      archivada: archivada ?? this.archivada,
    );
  }
}
