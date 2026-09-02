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
- Persistencia local SQLite para clientes, vencimientos, estados y pagos.
- Perfil profesional persistente del contador.
- Dashboard visual de declaraciones, recaudo y cartera.
- Edición persistente de fechas de vencimiento y honorarios.
- Identidad visual e íconos propios de ContaPlazo para Android e iOS.

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

El proyecto es un MVP. Los datos operativos se conservan en una base SQLite y los documentos se guardan en el almacenamiento privado de la aplicación. La sincronización segura en la nube se incorporará en una siguiente iteración.
