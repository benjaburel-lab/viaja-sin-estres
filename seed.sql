-- ============================================================
-- SEED.SQL
-- Datos demo para probar el esquema y las políticas RLS
-- Ejecutar TERCERO, después de schema.sql y policies.sql
-- ============================================================

-- Viaje 1: activo, con itinerario completo (para probar acceso público)
insert into viajes (id, codigo, titulo, destino, fecha_inicio, fecha_fin, descripcion, info_importante, activo)
values (
  '11111111-1111-1111-1111-111111111111',
  'BAR-8F42K',
  'Bariloche en grupo',
  'San Carlos de Bariloche',
  '2026-12-10',
  '2026-12-15',
  'Viaje grupal a la Patagonia con actividades al aire libre y excursiones guiadas.',
  'Llevar documento vigente. Punto de encuentro: Terminal de Ómnibus, 07:00.',
  true
);

-- Viaje 2: inactivo (para probar que NO se puede acceder vía RPC)
insert into viajes (id, codigo, titulo, destino, fecha_inicio, fecha_fin, descripcion, activo)
values (
  '22222222-2222-2222-2222-222222222222',
  'CAT-9X31M',
  'Cataratas del Iguazú (viaje de prueba, inactivo)',
  'Puerto Iguazú',
  '2026-08-01',
  '2026-08-05',
  'Viaje de ejemplo marcado como inactivo a propósito.',
  false
);

-- Actividades del viaje 1
insert into actividades (viaje_id, dia, fecha, hora, titulo, descripcion, lugar, orden) values
('11111111-1111-1111-1111-111111111111', 1, '2026-12-10', '09:00', 'Llegada y check-in', 'Recepción en el hotel base', 'Hotel Llao Llao', 1),
('11111111-1111-1111-1111-111111111111', 1, '2026-12-10', '19:00', 'Cena de bienvenida', 'Cena grupal para conocer al resto de los viajeros', 'Restaurante Cerro Catedral', 2),
('11111111-1111-1111-1111-111111111111', 2, '2026-12-11', '08:30', 'Excursión Circuito Chico', 'Recorrido en combi por los principales miradores', 'Circuito Chico', 1),
('11111111-1111-1111-1111-111111111111', 3, '2026-12-12', '10:00', 'Trekking Cerro Campanario', 'Subida en aerosilla y caminata panorámica', 'Cerro Campanario', 1);

-- Traslados del viaje 1
insert into traslados (viaje_id, tipo, origen, destino, fecha, hora, detalle, orden) values
('11111111-1111-1111-1111-111111111111', 'vuelo', 'Buenos Aires (AEP)', 'Bariloche (BRC)', '2026-12-10', '06:30', 'Aerolíneas Argentinas AR1234', 1),
('11111111-1111-1111-1111-111111111111', 'combi', 'Aeropuerto Bariloche', 'Hotel Llao Llao', '2026-12-10', '08:30', 'Traslado compartido incluido', 2),
('11111111-1111-1111-1111-111111111111', 'vuelo', 'Bariloche (BRC)', 'Buenos Aires (AEP)', '2026-12-15', '20:00', 'Aerolíneas Argentinas AR1235', 3);

-- Archivos del viaje 1 (paths de ejemplo; los objetos reales se
-- suben después desde el panel admin, esto es solo para probar
-- la relación y las políticas de Storage)
insert into archivos (viaje_id, tipo, nombre, path_storage, bucket, es_privado, orden) values
('11111111-1111-1111-1111-111111111111', 'pdf', 'Itinerario completo.pdf', 'viajes/11111111-1111-1111-1111-111111111111/documentos/itinerario.pdf', 'documentos', false, 1),
('11111111-1111-1111-1111-111111111111', 'imagen', 'Foto Circuito Chico', 'viajes/11111111-1111-1111-1111-111111111111/imagenes/circuito-chico.jpg', 'imagenes', false, 1);

-- Avisos del viaje 1
insert into avisos (viaje_id, mensaje) values
('11111111-1111-1111-1111-111111111111', 'Se actualizó el horario del traslado de regreso: ahora sale a las 20:00 en lugar de 18:00.'),
('11111111-1111-1111-1111-111111111111', 'Recordatorio: llevar ropa de abrigo, las temperaturas bajan mucho por la noche.');
