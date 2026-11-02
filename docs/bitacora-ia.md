## Laboratorio S16 — CRUD de categorías y migración SQLite

**Herramienta de IA utilizada:** ChatGPT

**Objetivo:** Implementar un módulo CRUD de categorías con almacenamiento persistente en SQLite y comprobar la migración de la base de datos de la versión 1 a la versión 2.

### Actividades realizadas

1. Creación del modelo de categorías y configuración de SQLite.
2. Implementación del repositorio para crear, consultar, actualizar, eliminar, archivar y restaurar categorías.
3. Integración de Riverpod para actualizar los listados.
4. Desarrollo de las pantallas de administración y del formulario compartido para crear y editar.
5. Implementación de validaciones para nombres duplicados y eliminación de categorías con gastos asociados.
6. Elaboración de pruebas automatizadas para el CRUD y la migración SQLite.

### Problemas y soluciones

Durante las pruebas se detectó que el método `getVersion()` no estaba disponible en la API utilizada. Se corrigió consultando la versión mediante `PRAGMA user_version`.

También se configuraron bases de datos temporales para ejecutar las pruebas sin modificar la información real de la aplicación.

### Verificaciones realizadas

- `flutter analyze`: sin errores.
- Prueba automatizada de migración SQLite: aprobada.
- Pruebas del repositorio de categorías: seis aprobadas.
- `flutter test`: trece pruebas aprobadas.

### Uso responsable de la IA

ChatGPT se utilizó como apoyo para generar código, explicar los componentes, identificar errores y proponer soluciones. Los resultados fueron revisados mediante ejecución de la aplicación y pruebas automatizadas.

### Resultado

Se implementó el CRUD de categorías y se comprobaron las operaciones del repositorio y la migración de SQLite mediante pruebas automatizadas.