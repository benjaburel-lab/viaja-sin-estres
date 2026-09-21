# Viaja Sin Estrés — paquete limpio

- La página principal real está en `index.html` en la raíz.
- Se eliminó la dependencia de `public/` para evitar errores 404 en GitHub Pages.
- Se ajustaron las rutas de `shared/`, `assets/` y `viaje/` para funcionar desde la raíz.
- Se conservaron los archivos de administración, portal, configuración y SQL.
- No se modificó Supabase ni se crearon viajes.

## Actualización — código QR

- Se incorporó un botón `▦` en las acciones de cada viaje del dashboard.
- El botón abre un modal con el código QR del enlace público del viaje.
- El modal permite descargar el QR en formato PNG y copiar el enlace público.
- El QR se genera en el navegador mediante `qrcodejs` cargado desde CDN.
- El enlace se construye respetando la ruta del repositorio de GitHub Pages.

## Antes de entregar

1. Subir/reemplazar el contenido de este paquete en el repositorio de GitHub.
2. Entrar al dashboard, crear o editar un viaje activo.
3. En el listado, pulsar el botón `▦` para generar el QR.
4. Escanear el QR con un teléfono y verificar que abre el portal correcto.
5. Descargar el PNG del QR para compartirlo con los viajeros.

> Este paquete no contiene viajes reales ni modifica los datos existentes en Supabase.
