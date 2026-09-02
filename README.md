# ContaPlazo

Aplicación móvil multiplataforma para apoyar a contadores en la gestión de clientes, declaraciones de renta, documentos, vencimientos y pagos.

## Funciones disponibles

- Panel de declaraciones pendientes y próximos vencimientos.
- Registro y consulta de clientes.
- Seguimiento del estado de cada declaración.
- Expediente documental privado por cliente.
- Carga de archivos PDF, imágenes, Word y Excel.
- Apertura y eliminación controlada de documentos.
- Registro del pago de honorarios y resumen de cartera.

## Tecnologías

- Flutter y Dart.
- Android e iOS desde una base de código compartida.
- `file_picker`, `path_provider` y `open_filex` para la gestión documental.

## Ejecutar el proyecto

```bash
flutter pub get
flutter run
```

## Verificación

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Estado actual

El proyecto es un MVP. Los documentos se guardan en el almacenamiento privado de la aplicación. La persistencia completa de clientes y la sincronización segura en la nube se incorporarán en las siguientes iteraciones.
