// ============================================================
// shared/supabaseClient.js
// Inicialización centralizada del cliente Supabase.
//
// Orden requerido en los HTML:
// 1. Supabase JS CDN
// 2. ../shared/config.js
// 3. ../shared/supabaseClient.js
//
// IMPORTANTE:
// Nunca utilizar la service_role key en el navegador.
// Usar únicamente la Publishable/Anon key.
// ============================================================

(function () {
  'use strict';

  // Leer la configuración pública desde shared/config.js
  const config = window.SUPABASE_CONFIG || {};

  const SUPABASE_URL = config.url || '';
  const SUPABASE_ANON_KEY = config.key || '';

  // URL base del sitio
  // Se utiliza para generar los enlaces públicos de los viajes.
  const SITE_URL =
    window.location.origin && window.location.origin !== 'null'
      ? window.location.origin
      : 'https://TU-DOMINIO.com';

  // Exponer SITE_URL globalmente
  window.SITE_URL = SITE_URL;

  // Verificar la configuración
  const configuracionInvalida =
    !SUPABASE_URL ||
    !SUPABASE_ANON_KEY ||
    SUPABASE_URL.includes('PEGAR_PROJECT_URL_AQUI') ||
    SUPABASE_ANON_KEY.includes('PEGAR_PUBLISHABLE_KEY_AQUI');

  if (configuracionInvalida) {
    console.warn(
      '%c⚠️ Supabase no configurado correctamente',
      'color: orange; font-weight: bold;',
      '\nRevisá el archivo shared/config.js.'
    );
  }

  // Verificar que la librería de Supabase se haya cargado
  if (
    typeof window.supabase === 'undefined' ||
    typeof window.supabase.createClient !== 'function'
  ) {
    console.error(
      '❌ No se encontró la librería de Supabase. ' +
      'Verificá que el CDN esté cargado antes de este archivo.'
    );

    window.supabaseClient = null;
    return;
  }

  // Crear el cliente de Supabase
  const client = window.supabase.createClient(
    SUPABASE_URL || 'https://placeholder.supabase.co',
    SUPABASE_ANON_KEY || 'placeholder'
  );

  // Exponer el cliente globalmente
  window.supabaseClient = client;

  console.log('✅ Cliente Supabase inicializado correctamente.');
})();