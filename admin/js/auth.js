// ============================================================
// admin/js/auth.js
// Módulo de autenticación para el panel admin.
// Depende de: supabaseClient (variable global de supabaseClient.js)
//
// Expone:
//   requireAdmin()  → verifica sesión + permisos, redirige si falla
//   logout()        → cierra sesión y va al login
// ============================================================

'use strict';

/**
 * Verifica que haya sesión activa Y que el usuario sea admin
 * (app_metadata.role === 'admin').
 *
 * - Si no hay sesión  → redirige a login.html
 * - Si es autenticado pero sin rol admin → cierra sesión y redirige
 *   con ?error=unauthorized para mostrar un aviso en login.
 *
 * @returns {Promise<Object|null>} session si todo está bien, null si redirigió
 */
async function requireAdmin() {
  let session;

  try {
    const { data, error } = await supabaseClient.auth.getSession();
    if (error) throw error;
    session = data.session;
  } catch (err) {
    console.error('Error al obtener sesión:', err.message);
    window.location.href = 'login.html';
    return null;
  }

  // Sin sesión → login
  if (!session) {
    window.location.href = 'login.html';
    return null;
  }

  // Con sesión pero sin rol admin → cerrar sesión y login con aviso
  const role = session.user?.app_metadata?.role;
  if (role !== 'admin') {
    console.warn(
      'Sesión activa pero sin permisos de admin.',
      'Configurá app_metadata.role = "admin" para este usuario en el Dashboard de Supabase.'
    );
    await supabaseClient.auth.signOut();
    window.location.href = 'login.html?error=unauthorized';
    return null;
  }

  return session;
}

/**
 * Cierra la sesión activa y redirige al login.
 */
async function logout() {
  try {
    await supabaseClient.auth.signOut();
  } catch (err) {
    console.error('Error al cerrar sesión:', err.message);
  }
  window.location.href = 'login.html';
}

/**
 * Escucha cambios de estado de autenticación.
 * Si la sesión expira mientras el usuario está en el dashboard,
 * lo redirige automáticamente al login.
 */
supabaseClient.auth.onAuthStateChange((event) => {
  const enDashboard = window.location.pathname.toLowerCase().includes('dashboard');
  if (event === 'SIGNED_OUT' && enDashboard) {
    window.location.href = 'login.html';
  }
});
