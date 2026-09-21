// ============================================================
// admin/js/viajes.js
// CRUD completo de viajes para el panel admin.
// ============================================================

'use strict';

// ─── Estado del módulo ──────────────────────────────────────
let _viajes = [];
let _editingId = null;
let _confirmCb = null;

// ─── Inicialización ─────────────────────────────────────────

async function initDashboard() {
  const session = await requireAdmin();
  if (!session) return;

  const email = session.user.email || '';
  const inicial = email[0]?.toUpperCase() || 'A';

  _setText('user-email', email);
  _setText('user-avatar', inicial);

  document
    .getElementById('form-viaje')
    .addEventListener('submit', handleFormSubmit);

  document
    .getElementById('modal-overlay')
    .addEventListener('click', (e) => {
      if (e.target.id === 'modal-overlay') cerrarModal();
    });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      cerrarModal();
      cerrarConfirm();
    }
  });

  await cargarViajes();
}

// ─── Operaciones con Supabase ────────────────────────────────

async function cargarViajes() {
  _showLoader(true);

  const { data, error } = await supabaseClient
    .from('viajes')
    .select('*')
    .order('created_at', { ascending: false });

  _showLoader(false);

  if (error) {
    console.error('cargarViajes:', error);
    _errorTabla(
      'No se pudieron cargar los viajes. Verificá tu conexión y permisos.'
    );
    return;
  }

  _viajes = data || [];
  _renderTabla();
  _renderStats();
}

async function _crearViaje(datos) {
  const { data, error } = await supabaseClient
    .from('viajes')
    .insert([datos])
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      throw new Error(
        'Ese código ya existe. Hacé clic en "↻ Generar" para obtener uno nuevo.'
      );
    }

    if (error.code === '23514') {
      throw new Error(
        'El formato del código es inválido. Debe ser tipo BAR-8F42K.'
      );
    }

    throw new Error(error.message);
  }

  return data;
}

async function _actualizarViaje(id, datos) {
  const { error } = await supabaseClient
    .from('viajes')
    .update(datos)
    .eq('id', id);

  if (error) {
    throw new Error(error.message);
  }
}

async function _eliminarViaje(id) {
  const { error } = await supabaseClient
    .from('viajes')
    .delete()
    .eq('id', id);

  if (error) {
    throw new Error(error.message);
  }
}

async function _cambiarActivo(id, nuevoEstado) {
  const { error } = await supabaseClient
    .from('viajes')
    .update({ activo: nuevoEstado })
    .eq('id', id);

  if (error) {
    throw new Error(error.message);
  }
}

// ─── Generación de código ────────────────────────────────────

const _CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

function _rndStr(len) {
  return Array.from(
    { length: len },
    () => _CHARS[Math.floor(Math.random() * _CHARS.length)]
  ).join('');
}

async function _generarCodigoUnico() {
  for (let i = 0; i < 10; i++) {
    const codigo = `${_rndStr(3)}-${_rndStr(5)}`;

    const { data } = await supabaseClient
      .from('viajes')
      .select('id')
      .eq('codigo', codigo)
      .maybeSingle();

    if (!data) return codigo;
  }

  return `${_rndStr(4)}-${_rndStr(6)}`;
}

async function regenerarCodigo() {
  const btn = document.getElementById('btn-regen');
  const input = document.getElementById('f-codigo');

  btn.disabled = true;
  btn.textContent = '...';

  try {
    input.value = await _generarCodigoUnico();
  } catch {
    mostrarToast('Error al generar código. Intentá de nuevo.', 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = '↻ Generar';
  }
}

// ─── Links públicos ──────────────────────────────────────────

function generarLink(codigo) {
  return `${SITE_URL}/viaje/?c=${encodeURIComponent(codigo)}`;
}

function abrirViaje(codigo) {
  const url = generarLink(codigo);
  window.open(url, '_blank', 'noopener,noreferrer');
}

async function copiarLink(codigo) {
  const url = generarLink(codigo);

  try {
    await navigator.clipboard.writeText(url);
  } catch {
    const tmp = Object.assign(
      document.createElement('textarea'),
      { value: url }
    );

    Object.assign(tmp.style, {
      position: 'fixed',
      opacity: '0'
    });

    document.body.appendChild(tmp);
    tmp.focus();
    tmp.select();
    document.execCommand('copy');
    tmp.remove();
  }

  mostrarToast('🔗 Link copiado', 'success');
}

// ─── Modal Crear / Editar ────────────────────────────────────

async function abrirModalCrear() {
  _editingId = null;
  _resetForm();

  document.getElementById('modal-titulo').textContent = 'Nuevo viaje';
  document.getElementById('btn-guardar').textContent = 'Crear viaje';

  const codigoInput = document.getElementById('f-codigo');
  const regenBtn = document.getElementById('btn-regen');

  codigoInput.readOnly = false;
  regenBtn.style.display = '';

  document.getElementById('f-activo').checked = true;

  await regenerarCodigo();

  _abrirModal();
}

function abrirModalEditarPorId(id) {
  const viaje = _viajes.find((item) => item.id === id);

  if (!viaje) return;

  _editingId = id;
  _resetForm();

  document.getElementById('modal-titulo').textContent = 'Editar viaje';
  document.getElementById('btn-guardar').textContent = 'Guardar cambios';

  document.getElementById('f-codigo').value = viaje.codigo;
  document.getElementById('f-titulo').value = viaje.titulo;
  document.getElementById('f-destino').value = viaje.destino;
  document.getElementById('f-fecha-inicio').value = viaje.fecha_inicio;
  document.getElementById('f-fecha-fin').value = viaje.fecha_fin;
  document.getElementById('f-descripcion').value =
    viaje.descripcion || '';
  document.getElementById('f-info').value =
    viaje.info_importante || '';
  document.getElementById('f-activo').checked = viaje.activo;

  document.getElementById('f-codigo').readOnly = true;
  document.getElementById('btn-regen').style.display = 'none';

  _abrirModal();
}

function _abrirModal() {
  document.getElementById('modal-overlay').classList.add('active');

  setTimeout(() => {
    document.getElementById('f-titulo').focus();
  }, 80);
}

function cerrarModal() {
  document.getElementById('modal-overlay').classList.remove('active');
  _editingId = null;
}

function _resetForm() {
  document.getElementById('form-viaje').reset();
  document.getElementById('f-error').classList.add('hidden');
}

// ─── Formulario ──────────────────────────────────────────────

async function handleFormSubmit(e) {
  e.preventDefault();

  const btn = document.getElementById('btn-guardar');
  const errorEl = document.getElementById('f-error');

  errorEl.classList.add('hidden');

  const datos = {
    codigo: document.getElementById('f-codigo').value.trim().toUpperCase(),
    titulo: document.getElementById('f-titulo').value.trim(),
    destino: document.getElementById('f-destino').value.trim(),
    fecha_inicio: document.getElementById('f-fecha-inicio').value,
    fecha_fin: document.getElementById('f-fecha-fin').value,
    descripcion:
      document.getElementById('f-descripcion').value.trim() || null,
    info_importante:
      document.getElementById('f-info').value.trim() || null,
    activo: document.getElementById('f-activo').checked
  };

  const errMsg = _validar(datos);

  if (errMsg) {
    _showFormError(errMsg);
    return;
  }

  btn.disabled = true;

  const labelOriginal = btn.textContent;
  btn.textContent = 'Guardando...';

  try {
    if (_editingId) {
      const { codigo: _ignorar, ...sinCodigo } = datos;

      await _actualizarViaje(_editingId, sinCodigo);

      mostrarToast('✅ Viaje actualizado', 'success');
    } else {
      await _crearViaje(datos);

      mostrarToast('✅ Viaje creado', 'success');
    }

    cerrarModal();
    await cargarViajes();
  } catch (err) {
    _showFormError(err.message);
  } finally {
    btn.disabled = false;
    btn.textContent = labelOriginal;
  }
}

function _validar(d) {
  const reCodigo = /^[A-Z0-9]{2,6}-[A-Z0-9]{4,8}$/;

  if (!d.titulo) {
    return 'El título es obligatorio.';
  }

  if (!d.destino) {
    return 'El destino es obligatorio.';
  }

  if (!d.fecha_inicio) {
    return 'La fecha de inicio es obligatoria.';
  }

  if (!d.fecha_fin) {
    return 'La fecha de fin es obligatoria.';
  }

  if (d.fecha_fin < d.fecha_inicio) {
    return 'La fecha de fin debe ser igual o posterior al inicio.';
  }

  if (!d.codigo) {
    return 'El código es obligatorio. Hacé clic en "↻ Generar".';
  }

  if (!reCodigo.test(d.codigo)) {
    return 'Formato de código inválido. Debe ser tipo BAR-8F42K.';
  }

  return null;
}

function _showFormError(msg) {
  const el = document.getElementById('f-error');

  el.textContent = msg;
  el.classList.remove('hidden');
}

// ─── Acciones de tabla ───────────────────────────────────────

function handleEliminar(id) {
  const viaje = _viajes.find((item) => item.id === id);

  if (!viaje) return;

  mostrarConfirm(
    `¿Eliminar "${viaje.titulo}"?\n\nSe eliminarán también todas sus actividades, traslados, archivos y avisos. Esta acción no se puede deshacer.`,
    async () => {
      try {
        await _eliminarViaje(id);
        mostrarToast('🗑️ Viaje eliminado', 'success');
        await cargarViajes();
      } catch (err) {
        mostrarToast('Error al eliminar: ' + err.message, 'error');
      }
    }
  );
}

async function handleToggle(id, nuevoEstado) {
  const viaje = _viajes.find((item) => item.id === id);

  if (!viaje) return;

  const estadoAnterior = viaje.activo;

  viaje.activo = nuevoEstado;
  _renderStats();

  try {
    await _cambiarActivo(id, nuevoEstado);

    mostrarToast(
      nuevoEstado ? '✅ Viaje activado' : '🔒 Viaje desactivado',
      nuevoEstado ? 'success' : 'warning'
    );
  } catch (err) {
    viaje.activo = estadoAnterior;

    const toggle = document.querySelector(`[data-toggle="${id}"]`);

    if (toggle) {
      toggle.checked = estadoAnterior;
    }

    _renderStats();

    mostrarToast(
      'Error al cambiar estado: ' + err.message,
      'error'
    );
  }
}

// ─── Confirm dialog ──────────────────────────────────────────

function mostrarConfirm(mensaje, callback) {
  _confirmCb = callback;

  document.getElementById('confirm-msg').textContent = mensaje;
  document.getElementById('confirm-overlay').classList.add('active');
}

function cerrarConfirm() {
  document.getElementById('confirm-overlay').classList.remove('active');
  _confirmCb = null;
}

async function ejecutarConfirm() {
  if (_confirmCb) {
    const callback = _confirmCb;

    cerrarConfirm();
    await callback();
  }
}

// ─── Toast ───────────────────────────────────────────────────

function mostrarToast(mensaje, tipo = 'success') {
  const container = document.getElementById('toast-container');

  const el = document.createElement('div');

  el.className = `toast toast-${tipo}`;
  el.textContent = mensaje;

  container.appendChild(el);

  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      el.classList.add('show');
    });
  });

  setTimeout(() => {
    el.classList.remove('show');

    setTimeout(() => {
      el.remove();
    }, 350);
  }, 3500);
}

// ─── Render ──────────────────────────────────────────────────

function _renderTabla() {
  const tbody = document.getElementById('tbody-viajes');
  const empty = document.getElementById('empty-state');
  const tabla = document.querySelector('.tabla-wrapper');

  if (_viajes.length === 0) {
    empty.classList.remove('hidden');
    tabla.classList.add('hidden');
    return;
  }

  empty.classList.add('hidden');
  tabla.classList.remove('hidden');

  tbody.innerHTML = _viajes.map(_renderFila).join('');
}

function _renderFila(v) {
  const fi = _fmtFecha(v.fecha_inicio);
  const ff = _fmtFecha(v.fecha_fin);
  const badgeCls = v.activo ? 'badge-primary' : 'badge-neutral';
  const id = _esc(v.id);

  return `
  <tr>
    <td>
      <span class="badge ${badgeCls}">
        ${_esc(v.codigo)}
      </span>
    </td>

    <td>
      <div class="td-titulo-main">${_esc(v.titulo)}</div>
      <div class="td-titulo-sub">${_esc(v.destino)}</div>
    </td>

    <td class="td-fechas col-fechas">
      ${fi} → ${ff}
    </td>

    <td>
      <label
        class="toggle"
        title="${v.activo ? 'Activo — click para desactivar' : 'Inactivo — click para activar'}"
      >
        <input
          type="checkbox"
          ${v.activo ? 'checked' : ''}
          data-toggle="${id}"
          onchange="handleToggle('${id}', this.checked)"
        >
        <span class="toggle-slider"></span>
      </label>
    </td>

    <td>
      <div class="td-actions">

        <button
          class="btn btn-ghost btn-sm"
          title="Editar datos del viaje"
          onclick="abrirModalEditarPorId('${id}')"
        >
          ✏️
        </button>

        <button
          class="btn btn-primary btn-sm"
          title="Gestionar contenido"
          onclick="window.location.href='viaje-editor.html?id=${id}'"
        >
          📝
        </button>

        <button
          class="btn btn-primary btn-sm"
          title="Abrir portal público del viajero"
          onclick="abrirViaje('${_esc(v.codigo)}')"
        >
          👁️
        </button>

        <button
          class="btn btn-ghost btn-sm"
          title="Copiar link público"
          onclick="copiarLink('${_esc(v.codigo)}')"
        >
          🔗
        </button>

        <button
          class="btn btn-danger btn-sm"
          title="Eliminar viaje"
          onclick="handleEliminar('${id}')"
        >
          🗑️
        </button>

      </div>
    </td>
  </tr>
  `.trim();
}

function _renderStats() {
  const total = _viajes.length;
  const activos = _viajes.filter((v) => v.activo).length;
  const inactivos = total - activos;

  _setText('stat-total', total);
  _setText('stat-activos', activos);
  _setText('stat-inactivos', inactivos);
}

// ─── Helpers UI ──────────────────────────────────────────────

function _showLoader(visible) {
  const loader = document.getElementById('loading-state');
  const tabla = document.querySelector('.tabla-wrapper');
  const empty = document.getElementById('empty-state');

  if (visible) {
    loader?.classList.remove('hidden');
    tabla?.classList.add('hidden');
    empty?.classList.add('hidden');
  } else {
    loader?.classList.add('hidden');
  }
}

function _errorTabla(msg) {
  const tabla = document.querySelector('.tabla-wrapper');

  tabla?.classList.remove('hidden');

  const tbody = document.getElementById('tbody-viajes');

  if (tbody) {
    tbody.innerHTML = `
      <tr>
        <td
          colspan="5"
          class="text-center"
          style="padding:3rem;color:var(--color-danger);font-size:var(--text-sm)"
        >
          ⚠️ ${_esc(msg)}
        </td>
      </tr>
    `;
  }
}

// ─── Utilidades ──────────────────────────────────────────────

function _esc(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function _fmtFecha(s) {
  if (!s) return '—';

  const [y, m, d] = s.split('-');

  return `${d}/${m}/${y}`;
}

function _setText(id, val) {
  const el = document.getElementById(id);

  if (el) {
    el.textContent = val;
  }
}