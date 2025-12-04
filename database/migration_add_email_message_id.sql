-- ========================================
-- Migración: Agregar columna email_message_id
-- Fecha: 2024-12-04
-- Descripción: Agrega columna para tracking de mensajes de SES
-- ========================================

-- Agregar columna email_message_id a informes_medicos
ALTER TABLE informes_medicos 
ADD COLUMN IF NOT EXISTS email_message_id VARCHAR(255);

-- Crear índice para búsquedas por message_id
CREATE INDEX IF NOT EXISTS idx_informes_email_message_id 
ON informes_medicos(email_message_id);

-- Agregar comentario explicativo
COMMENT ON COLUMN informes_medicos.email_message_id 
IS 'ID del mensaje de Amazon SES para tracking y verificación';

-- Recrear vista informes_completos para incluir el nuevo campo
CREATE OR REPLACE VIEW informes_completos AS
SELECT 
    im.id,
    im.tipo_examen,
    im.fecha_examen,
    im.presion_arterial,
    im.frecuencia_cardiaca,
    im.frecuencia_respiratoria,
    im.temperatura,
    im.saturacion_oxigeno,
    im.peso,
    im.altura,
    im.imc,
    im.perimetro_abdominal,
    im.vision,
    im.audiometria,
    im.antecedentes_medicos,
    im.examen_fisico,
    im.examenes_adicionales,
    im.observaciones,
    im.pdf_s3_path,
    im.origen,
    im.nivel_riesgo,
    im.justificacion_riesgo,
    im.resumen_ejecutivo,
    im.recomendaciones,
    im.procesado_por_ia,
    im.email_enviado,
    im.fecha_email_enviado,
    im.email_message_id,
    t.nombre as trabajador_nombre,
    t.documento as trabajador_documento,
    t.fecha_nacimiento as trabajador_fecha_nacimiento,
    t.edad as trabajador_edad,
    t.genero as trabajador_genero,
    t.puesto as trabajador_puesto,
    t.cargo as trabajador_cargo,
    c.nombre as contratista_nombre,
    c.ruc as contratista_ruc,
    c.email as contratista_email,
    c.telefono as contratista_telefono,
    im.created_at,
    im.updated_at
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
JOIN contratistas c ON im.contratista_id = c.id;

-- ========================================
-- Fin de la migración
-- ========================================
