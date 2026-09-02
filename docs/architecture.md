# Arquitectura cloud de ContaPlazo

ContaPlazo utiliza una arquitectura híbrida **offline-first**. La aplicación conserva los datos operativos en SQLite y los documentos en el almacenamiento privado del dispositivo. Cuando existe conexión y se proporcionan las variables de Supabase, sincroniza la información con servicios administrados en la nube.

## Componentes

- **Flutter:** interfaz móvil compartida para Android e iOS.
- **SQLite:** clientes, vencimientos, honorarios, pagos y perfil del contador.
- **Supabase Auth:** identidad anónima persistente para el MVP, migrable a correo y contraseña.
- **PostgreSQL:** clientes y perfil profesional mediante la API de datos.
- **Supabase Storage:** documentos en un bucket privado de máximo 10 MB por archivo.
- **Row Level Security:** filtra filas y objetos por `auth.uid()`.

## Flujo principal

1. El contador registra o modifica información desde Flutter.
2. La aplicación confirma primero la operación en SQLite.
3. Si Supabase está configurado, realiza un `upsert` en PostgreSQL.
4. Los archivos se conservan localmente y se cargan al bucket privado bajo `usuario/cliente/archivo`.
5. Sin conexión, la aplicación continúa funcionando con la copia local.

## Seguridad

- La clave `service_role` nunca se incluye en la aplicación.
- La URL y la clave publicable se inyectan con `--dart-define-from-file`.
- Las tablas tienen RLS habilitado y no conceden acceso al rol `anon`.
- Storage valida el usuario en la primera carpeta del objeto.
- Los documentos no utilizan URLs públicas.

El diagrama fuente está disponible en [`docs/diagrams/architecture.mmd`](diagrams/architecture.mmd).
