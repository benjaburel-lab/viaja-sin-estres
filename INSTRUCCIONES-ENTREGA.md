# Viaja Sin Estrés — instrucciones de entrega

## Qué incluye esta versión

- Página principal en `index.html`.
- Portal público del viajero en `viaje/index.html`.
- Login y panel de administración en `admin/`.
- Gestión de itinerarios, traslados, avisos y archivos.
- Generación de enlaces públicos.
- Generación de códigos QR desde el dashboard.
- Descarga del QR en PNG y copia del enlace público.
- Configuración compartida de Supabase en `shared/`.

## Cómo reemplazarlo en GitHub

1. Abrí el repositorio `benjaburel-lab/viaja-sin-estres`.
2. Descargá este ZIP y descomprimilo en tu computadora.
3. En GitHub, abrí cada archivo que debas reemplazar y utilizá **Add file → Upload files** para subir los archivos correspondientes, respetando las carpetas.
4. Confirmá los cambios con **Commit changes**.
5. Esperá unos minutos a que GitHub Pages publique la nueva versión.
6. Probá la página principal, el login, el dashboard y un portal de viaje.

## Cómo generar un QR

1. Entrá al dashboard de administración.
2. Creá o seleccioná un viaje.
3. En el listado de viajes, buscá las acciones del viaje.
4. Presioná el botón `▦` — **Generar código QR**.
5. Verificá el enlace mostrado.
6. Presioná **Descargar QR** para guardar el PNG o **Copiar enlace** para compartir la URL.

## Importante

- No subir nunca una clave `service_role` al frontend.
- La clave incluida en `shared/config.js` debe ser únicamente pública (`publishable`/`anon`).
- No borrar viajes de Supabase sin confirmar previamente que son de prueba.
- Antes de entregar, probar el QR desde un teléfono usando datos móviles o una red diferente.
