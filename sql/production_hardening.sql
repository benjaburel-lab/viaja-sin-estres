-- Viajar Sin Estrés — endurecimiento de Storage para producción
-- Ejecutar UNA VEZ en Supabase SQL Editor después de policies.sql.
-- Objetivo: mantener el bucket documentos PRIVADO y entregar archivos
-- públicos del portal mediante URLs firmadas temporales.

update storage.buckets
set public = false
where id = 'documentos';

-- El bucket imagenes puede permanecer público porque contiene únicamente
-- imágenes destinadas a mostrarse públicamente en los portales activos.
update storage.buckets
set public = true
where id = 'imagenes';
