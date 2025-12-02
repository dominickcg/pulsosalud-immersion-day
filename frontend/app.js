/**
 * PulsoSalud - App Web para Workshop Día 1
 * Clasificación de Riesgo y Generación de Resúmenes con Amazon Bedrock
 */

// Estado global de la aplicación
let informesData = [];
let currentInformeId = null;

// ========================================
// Inicialización
// ========================================

document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 PulsoSalud App iniciada');
    console.log('📡 API Gateway URL:', API_GATEWAY_URL);
    
    // Cargar informes al iniciar
    loadInformes();
    
    // Event listeners
    document.getElementById('btn-volver').addEventListener('click', showVistaLista);
    document.getElementById('btn-clasificar').addEventListener('click', classifyInforme);
    document.getElementById('btn-generar-resumen').addEventListener('click', generateSummary);
    document.getElementById('btn-copiar-resumen').addEventListener('click', copyResumen);
});

// ========================================
// Navegación entre vistas
// ========================================

function showVistaLista() {
    document.getElementById('vista-lista').classList.remove('hidden');
    document.getElementById('vista-detalle').classList.add('hidden');
    currentInformeId = null;
    
    // Recargar informes para actualizar estados
    loadInformes();
}

function showVistaDetalle(informeId) {
    currentInformeId = informeId;
    document.getElementById('vista-lista').classList.add('hidden');
    document.getElementById('vista-detalle').classList.remove('hidden');
    
    // Cargar detalles del informe
    loadInformeDetail(informeId);
}

// ========================================
// API Calls
// ========================================

async function apiCall(endpoint, options = {}) {
    try {
        const url = `${API_GATEWAY_URL}${endpoint}`;
        console.log(`📡 API Call: ${options.method || 'GET'} ${url}`);
        
        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('✅ Response:', data);
        return data;
        
    } catch (error) {
        console.error('❌ API Error:', error);
        showError(`Error de conexión: ${error.message}`);
        throw error;
    }
}

// ========================================
// Cargar Lista de Informes
// ========================================

async function loadInformes() {
    try {
        showLoadingInformes();
        
        const data = await apiCall('informes');
        informesData = data.informes || data;
        
        renderInformesList(informesData);
        updateStats(informesData);
        
    } catch (error) {
        showErrorInformes('No se pudieron cargar los informes. Verifica la conexión con el API.');
    }
}

function showLoadingInformes() {
    const tbody = document.getElementById('informes-tbody');
    tbody.innerHTML = `
        <tr>
            <td colspan="6" class="px-6 py-12 text-center">
                <div class="flex flex-col items-center justify-center">
                    <svg class="animate-spin h-8 w-8 text-blue-600 mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <p class="text-gray-500">Cargando informes...</p>
                </div>
            </td>
        </tr>
    `;
}

function showErrorInformes(message) {
    const tbody = document.getElementById('informes-tbody');
    tbody.innerHTML = `
        <tr>
            <td colspan="6" class="px-6 py-12 text-center">
                <div class="flex flex-col items-center justify-center">
                    <svg class="h-12 w-12 text-red-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    <p class="text-gray-900 font-medium">${message}</p>
                    <button onclick="loadInformes()" class="mt-4 text-blue-600 hover:text-blue-700">
                        Reintentar
                    </button>
                </div>
            </td>
        </tr>
    `;
}

function renderInformesList(informes) {
    const tbody = document.getElementById('informes-tbody');
    
    if (!informes || informes.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" class="px-6 py-12 text-center text-gray-500">
                    No hay informes disponibles
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = informes.map(informe => `
        <tr class="hover:bg-gray-50 cursor-pointer transition-colors" onclick="showVistaDetalle(${informe.id})">
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                #${informe.id}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                ${informe.trabajador_nombre}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                ${informe.tipo_examen}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                ${formatPresion(informe.presion_arterial)}
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
                ${renderEstadoBadge(informe.nivel_riesgo)}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button class="text-blue-600 hover:text-blue-900" onclick="event.stopPropagation(); showVistaDetalle(${informe.id})">
                    Ver detalles →
                </button>
            </td>
        </tr>
    `).join('');
}

function renderEstadoBadge(nivelRiesgo) {
    if (!nivelRiesgo) {
        return '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">Sin clasificar</span>';
    }
    
    const badges = {
        'BAJO': '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">✓ Riesgo Bajo</span>',
        'MEDIO': '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">⚠ Riesgo Medio</span>',
        'ALTO': '<span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">⚠ Riesgo Alto</span>'
    };
    
    return badges[nivelRiesgo] || badges['BAJO'];
}

function updateStats(informes) {
    const total = informes.length;
    const clasificados = informes.filter(i => i.nivel_riesgo).length;
    const conResumen = informes.filter(i => i.resumen_ejecutivo).length;
    
    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-clasificados').textContent = clasificados;
    document.getElementById('stat-resumenes').textContent = conResumen;
}

// ========================================
// Cargar Detalle de Informe
// ========================================

async function loadInformeDetail(informeId) {
    try {
        // Buscar en datos cargados
        const informe = informesData.find(i => i.id === informeId);
        
        if (!informe) {
            showError('Informe no encontrado');
            showVistaLista();
            return;
        }
        
        // Poblar datos del trabajador
        document.getElementById('detalle-trabajador-nombre').textContent = informe.trabajador_nombre || '-';
        document.getElementById('detalle-trabajador-documento').textContent = informe.trabajador_documento || '-';
        document.getElementById('detalle-tipo-examen').textContent = informe.tipo_examen || '-';
        document.getElementById('detalle-fecha').textContent = formatFecha(informe.fecha_examen);
        
        // Poblar datos del examen
        document.getElementById('detalle-presion').textContent = formatPresion(informe.presion_arterial);
        document.getElementById('detalle-peso').textContent = informe.peso ? `${informe.peso} kg` : '-';
        document.getElementById('detalle-altura').textContent = informe.altura ? `${informe.altura} m` : '-';
        document.getElementById('detalle-vision').textContent = informe.vision || '-';
        document.getElementById('detalle-audiometria').textContent = informe.audiometria || '-';
        document.getElementById('detalle-observaciones').textContent = informe.observaciones || 'Sin observaciones';
        
        // Mostrar clasificación si existe
        if (informe.nivel_riesgo) {
            showClasificacionResult({
                nivel_riesgo: informe.nivel_riesgo,
                justificacion: informe.justificacion_riesgo || 'Clasificación previa',
                tiempo_procesamiento: '-',
                informes_anteriores_encontrados: 0
            });
        } else {
            hideClasificacionResult();
        }
        
        // Mostrar resumen si existe
        if (informe.resumen_ejecutivo) {
            showResumenResult({
                resumen: informe.resumen_ejecutivo,
                palabras: countWords(informe.resumen_ejecutivo),
                tiempo_procesamiento: '-',
                incluye_contexto_historico: false
            });
        } else {
            hideResumenResult();
        }
        
    } catch (error) {
        console.error('Error cargando detalle:', error);
        showError('Error cargando detalles del informe');
    }
}

// ========================================
// Clasificar Informe
// ========================================

async function classifyInforme() {
    if (!currentInformeId) return;
    
    const btn = document.getElementById('btn-clasificar');
    const originalText = btn.innerHTML;
    
    try {
        // Mostrar estado de carga
        btn.disabled = true;
        btn.innerHTML = `
            <svg class="animate-spin h-5 w-5 mr-2 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Clasificando con Bedrock Nova Pro...
        `;
        
        // Llamar API
        const result = await apiCall('classify', {
            method: 'POST',
            body: JSON.stringify({
                informe_id: currentInformeId
            })
        });
        
        // Mostrar resultado
        showClasificacionResult(result);
        
        // Actualizar datos locales
        const informe = informesData.find(i => i.id === currentInformeId);
        if (informe) {
            informe.nivel_riesgo = result.nivel_riesgo;
            informe.justificacion_riesgo = result.justificacion;
        }
        
    } catch (error) {
        console.error('Error clasificando:', error);
        showError('Error al clasificar el informe. Intenta nuevamente.');
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalText;
    }
}

function showClasificacionResult(result) {
    const container = document.getElementById('resultado-clasificacion');
    const card = document.getElementById('clasificacion-card');
    const icon = document.getElementById('clasificacion-icon');
    
    // Configurar colores según nivel de riesgo
    const configs = {
        'BAJO': {
            border: 'border-green-400',
            bg: 'bg-green-50',
            iconColor: 'text-green-400',
            textColor: 'text-green-800'
        },
        'MEDIO': {
            border: 'border-yellow-400',
            bg: 'bg-yellow-50',
            iconColor: 'text-yellow-400',
            textColor: 'text-yellow-800'
        },
        'ALTO': {
            border: 'border-red-400',
            bg: 'bg-red-50',
            iconColor: 'text-red-400',
            textColor: 'text-red-800'
        }
    };
    
    const config = configs[result.nivel_riesgo] || configs['BAJO'];
    
    card.className = `border-l-4 p-4 rounded ${config.border} ${config.bg}`;
    icon.className = `h-6 w-6 ${config.iconColor}`;
    
    document.getElementById('clasificacion-nivel').innerHTML = `
        <span class="${config.textColor}">Nivel de Riesgo: ${result.nivel_riesgo}</span>
    `;
    
    document.getElementById('clasificacion-justificacion').innerHTML = `
        <p class="text-gray-700">${result.justificacion}</p>
    `;
    
    document.getElementById('clasificacion-meta').textContent = 
        `Tiempo: ${result.tiempo_procesamiento} | Informes anteriores: ${result.informes_anteriores_encontrados}`;
    
    container.classList.remove('hidden');
}

function hideClasificacionResult() {
    document.getElementById('resultado-clasificacion').classList.add('hidden');
}

// ========================================
// Generar Resumen
// ========================================

async function generateSummary() {
    if (!currentInformeId) return;
    
    const btn = document.getElementById('btn-generar-resumen');
    const originalText = btn.innerHTML;
    
    try {
        // Mostrar estado de carga
        btn.disabled = true;
        btn.innerHTML = `
            <svg class="animate-spin h-5 w-5 mr-2 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Generando resumen con Bedrock Nova Pro...
        `;
        
        // Llamar API
        const result = await apiCall('summary', {
            method: 'POST',
            body: JSON.stringify({
                informe_id: currentInformeId
            })
        });
        
        // Mostrar resultado
        showResumenResult(result);
        
        // Actualizar datos locales
        const informe = informesData.find(i => i.id === currentInformeId);
        if (informe) {
            informe.resumen_ejecutivo = result.resumen;
        }
        
    } catch (error) {
        console.error('Error generando resumen:', error);
        
        // Mensaje específico si no está clasificado
        if (error.message.includes('clasificado')) {
            showError('Este informe debe ser clasificado primero. Haz clic en "Clasificar con IA".');
        } else {
            showError('Error al generar el resumen. Intenta nuevamente.');
        }
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalText;
    }
}

function showResumenResult(result) {
    const container = document.getElementById('resultado-resumen');
    
    document.getElementById('resumen-texto').textContent = result.resumen;
    
    const metaText = `${result.palabras} palabras | Tiempo: ${result.tiempo_procesamiento}`;
    const contextoText = result.incluye_contexto_historico ? ' | Con contexto histórico' : '';
    document.getElementById('resumen-meta').textContent = metaText + contextoText;
    
    container.classList.remove('hidden');
}

function hideResumenResult() {
    document.getElementById('resultado-resumen').classList.add('hidden');
}

async function copyResumen() {
    const texto = document.getElementById('resumen-texto').textContent;
    
    try {
        await navigator.clipboard.writeText(texto);
        
        const btn = document.getElementById('btn-copiar-resumen');
        const originalText = btn.textContent;
        btn.textContent = '✓ Copiado!';
        
        setTimeout(() => {
            btn.textContent = originalText;
        }, 2000);
        
    } catch (error) {
        console.error('Error copiando:', error);
        showError('No se pudo copiar al portapapeles');
    }
}

// ========================================
// Utilidades
// ========================================

function formatPresion(presion) {
    if (!presion) return '-';
    return `${presion} mmHg`;
}

function formatFecha(fecha) {
    if (!fecha) return '-';
    try {
        const date = new Date(fecha);
        return date.toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    } catch {
        return fecha;
    }
}

function countWords(text) {
    if (!text) return 0;
    return text.trim().split(/\s+/).length;
}

function showError(message) {
    // Crear toast de error
    const toast = document.createElement('div');
    toast.className = 'fixed top-4 right-4 bg-red-50 border-l-4 border-red-400 p-4 rounded shadow-lg z-50 max-w-md';
    toast.innerHTML = `
        <div class="flex">
            <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
            </div>
            <div class="ml-3">
                <p class="text-sm text-red-700">${message}</p>
            </div>
            <div class="ml-auto pl-3">
                <button onclick="this.parentElement.parentElement.parentElement.remove()" class="text-red-400 hover:text-red-600">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>
        </div>
    `;
    
    document.body.appendChild(toast);
    
    // Auto-remover después de 5 segundos
    setTimeout(() => {
        toast.remove();
    }, 5000);
}
