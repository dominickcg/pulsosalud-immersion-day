-- ========================================
-- Migración: Agregar campos detallados a informes médicos
-- Fecha: 2024
-- Descripción: Agrega campos adicionales para informes médicos más completos
-- ========================================

-- Agregar nuevos campos a la tabla trabajadores
ALTER TABLE trabajadores 
ADD COLUMN IF NOT EXISTS edad INT,
ADD COLUMN IF NOT EXISTS cargo VARCHAR(100);

-- Agregar RUC a contratistas
ALTER TABLE contratistas 
ADD COLUMN IF NOT EXISTS ruc VARCHAR(20);

-- Agregar nuevos campos a informes_medicos
ALTER TABLE informes_medicos
ADD COLUMN IF NOT EXISTS frecuencia_cardiaca INT,
ADD COLUMN IF NOT EXISTS frecuencia_respiratoria INT,
ADD COLUMN IF NOT EXISTS temperatura DECIMAL(3,1),
ADD COLUMN IF NOT EXISTS saturacion_oxigeno INT,
ADD COLUMN IF NOT EXISTS perimetro_abdominal INT,
ADD COLUMN IF NOT EXISTS antecedentes_medicos TEXT,
ADD COLUMN IF NOT EXISTS examen_fisico JSONB,
ADD COLUMN IF NOT EXISTS examenes_adicionales JSONB;

-- Actualizar campos existentes para permitir más caracteres
ALTER TABLE informes_medicos 
ALTER COLUMN vision TYPE VARCHAR(200),
ALTER COLUMN audiometria TYPE VARCHAR(200);

-- Comentarios en los nuevos campos
COMMENT ON COLUMN trabajadores.edad IS 'Edad del trabajador en años';
COMMENT ON COLUMN trabajadores.cargo IS 'Cargo o puesto del trabajador';
COMMENT ON COLUMN contratistas.ruc IS 'RUC de la empresa contratista';
COMMENT ON COLUMN informes_medicos.frecuencia_cardiaca IS 'Frecuencia cardíaca en latidos por minuto';
COMMENT ON COLUMN informes_medicos.frecuencia_respiratoria IS 'Frecuencia respiratoria en respiraciones por minuto';
COMMENT ON COLUMN informes_medicos.temperatura IS 'Temperatura corporal en grados Celsius';
COMMENT ON COLUMN informes_medicos.saturacion_oxigeno IS 'Saturación de oxígeno en porcentaje';
COMMENT ON COLUMN informes_medicos.perimetro_abdominal IS 'Perímetro abdominal en centímetros';
COMMENT ON COLUMN informes_medicos.antecedentes_medicos IS 'Antecedentes médicos del trabajador';
COMMENT ON COLUMN informes_medicos.examen_fisico IS 'Resultados del examen físico en formato JSON';
COMMENT ON COLUMN informes_medicos.examenes_adicionales IS 'Exámenes complementarios adicionales en formato JSON';

-- Actualizar la vista informes_completos
DROP VIEW IF EXISTS informes_completos;

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
