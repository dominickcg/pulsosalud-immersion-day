-- ========================================
-- Schema para Medical Reports Automation
-- Base de datos: medical_reports
-- PostgreSQL con extensión pgvector
-- ========================================

-- Habilitar extensión pgvector para embeddings (RAG)
CREATE EXTENSION IF NOT EXISTS vector;

-- ========================================
-- Tabla: trabajadores
-- ========================================
CREATE TABLE IF NOT EXISTS trabajadores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    documento VARCHAR(50) UNIQUE NOT NULL,
    fecha_nacimiento DATE,
    edad INT,
    genero VARCHAR(20),
    puesto VARCHAR(100),
    cargo VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para trabajadores
CREATE INDEX IF NOT EXISTS idx_trabajadores_documento ON trabajadores(documento);
CREATE INDEX IF NOT EXISTS idx_trabajadores_nombre ON trabajadores(nombre);

-- ========================================
-- Tabla: contratistas
-- ========================================
CREATE TABLE IF NOT EXISTS contratistas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    ruc VARCHAR(20),
    email VARCHAR(200) NOT NULL,
    telefono VARCHAR(50),
    direccion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para contratistas
CREATE INDEX IF NOT EXISTS idx_contratistas_email ON contratistas(email);
CREATE INDEX IF NOT EXISTS idx_contratistas_nombre ON contratistas(nombre);

-- ========================================
-- Tabla: informes_medicos
-- Tabla central que almacena todos los informes
-- ========================================
CREATE TABLE IF NOT EXISTS informes_medicos (
    id SERIAL PRIMARY KEY,
    trabajador_id INT NOT NULL,
    contratista_id INT NOT NULL,
    
    -- Datos del examen (del legacy o extraídos de PDF externo)
    tipo_examen VARCHAR(100) NOT NULL,
    fecha_examen TIMESTAMP NOT NULL,
    
    -- Signos vitales
    presion_arterial VARCHAR(20),
    frecuencia_cardiaca INT,
    frecuencia_respiratoria INT,
    temperatura DECIMAL(3,1),
    saturacion_oxigeno INT,
    peso DECIMAL(5,2),
    altura DECIMAL(3,2),
    imc DECIMAL(4,1),
    perimetro_abdominal INT,
    
    -- Exámenes complementarios
    vision VARCHAR(200),
    audiometria VARCHAR(200),
    
    -- Antecedentes médicos
    antecedentes_medicos TEXT,
    
    -- Examen físico (JSON con sistemas)
    examen_fisico JSONB,
    
    -- Exámenes adicionales (JSON con array de exámenes)
    examenes_adicionales JSONB,
    
    -- Observaciones y recomendaciones
    observaciones TEXT,
    
    -- Referencia al PDF
    pdf_s3_path VARCHAR(500),
    origen VARCHAR(20) DEFAULT 'LEGACY', -- 'LEGACY' o 'EXTERNO'
    
    -- Datos agregados por IA (inicialmente NULL)
    nivel_riesgo VARCHAR(20), -- 'BAJO', 'MEDIO', 'ALTO'
    justificacion_riesgo TEXT,
    resumen_ejecutivo TEXT,
    recomendaciones TEXT,
    
    -- Auditoría
    procesado_por_ia BOOLEAN DEFAULT FALSE,
    email_enviado BOOLEAN DEFAULT FALSE,
    fecha_email_enviado TIMESTAMP NULL,
    email_message_id VARCHAR(255), -- ID del mensaje de SES para tracking
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id) ON DELETE CASCADE,
    FOREIGN KEY (contratista_id) REFERENCES contratistas(id) ON DELETE CASCADE
);

-- Índices para informes_medicos
CREATE INDEX IF NOT EXISTS idx_informes_trabajador ON informes_medicos(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_informes_contratista ON informes_medicos(contratista_id);
CREATE INDEX IF NOT EXISTS idx_informes_fecha ON informes_medicos(fecha_examen DESC);
CREATE INDEX IF NOT EXISTS idx_informes_procesado ON informes_medicos(procesado_por_ia);
CREATE INDEX IF NOT EXISTS idx_informes_nivel_riesgo ON informes_medicos(nivel_riesgo);
CREATE INDEX IF NOT EXISTS idx_informes_origen ON informes_medicos(origen);
CREATE INDEX IF NOT EXISTS idx_informes_email_enviado ON informes_medicos(email_enviado);
CREATE INDEX IF NOT EXISTS idx_informes_email_message_id ON informes_medicos(email_message_id);

-- ========================================
-- Tabla: informes_embeddings
-- Almacena embeddings para RAG (usando pgvector)
-- ========================================
CREATE TABLE IF NOT EXISTS informes_embeddings (
    id SERIAL PRIMARY KEY,
    informe_id INT NOT NULL,
    trabajador_id INT NOT NULL,
    embedding vector(1024), -- Dimensión de embeddings de Amazon Titan Embeddings v2 (1024 dims)
    contenido TEXT, -- Texto del informe para referencia
    fecha_examen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (informe_id) REFERENCES informes_medicos(id) ON DELETE CASCADE,
    FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id) ON DELETE CASCADE
);

-- Índice para búsqueda de similitud eficiente con pgvector
-- Usa IVFFlat para búsquedas aproximadas rápidas
CREATE INDEX IF NOT EXISTS idx_embedding_vector ON informes_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Índice para filtrar por trabajador
CREATE INDEX IF NOT EXISTS idx_embedding_trabajador ON informes_embeddings(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_embedding_informe ON informes_embeddings(informe_id);

-- ========================================
-- Tabla: laboratorio_resultados
-- Almacena resultados de laboratorio detallados
-- ========================================
CREATE TABLE IF NOT EXISTS laboratorio_resultados (
    id SERIAL PRIMARY KEY,
    informe_id INT NOT NULL,
    
    -- Hematología
    hemoglobina DECIMAL(4,1),
    hematocrito DECIMAL(4,1),
    globulos_blancos INT,
    plaquetas INT,
    
    -- Perfil lipídico
    colesterol_total INT,
    colesterol_hdl INT,
    colesterol_ldl INT,
    trigliceridos INT,
    
    -- Glucosa
    glucosa_basal INT,
    
    -- Función renal
    creatinina DECIMAL(3,1),
    urea INT,
    acido_urico DECIMAL(3,1),
    
    -- Función hepática
    tgo INT,
    tgp INT,
    bilirrubina_total DECIMAL(3,1),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (informe_id) REFERENCES informes_medicos(id) ON DELETE CASCADE
);

-- Índice para laboratorio
CREATE INDEX IF NOT EXISTS idx_laboratorio_informe ON laboratorio_resultados(informe_id);

-- ========================================
-- Tabla: historial_emails
-- Registro de emails enviados
-- ========================================
CREATE TABLE IF NOT EXISTS historial_emails (
    id SERIAL PRIMARY KEY,
    informe_id INT NOT NULL,
    destinatario VARCHAR(200) NOT NULL,
    asunto VARCHAR(500),
    cuerpo TEXT,
    estado VARCHAR(50), -- 'ENVIADO', 'FALLIDO', 'REBOTADO'
    mensaje_error TEXT,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (informe_id) REFERENCES informes_medicos(id) ON DELETE CASCADE
);

-- Índices para historial_emails
CREATE INDEX IF NOT EXISTS idx_emails_informe ON historial_emails(informe_id);
CREATE INDEX IF NOT EXISTS idx_emails_estado ON historial_emails(estado);
CREATE INDEX IF NOT EXISTS idx_emails_fecha ON historial_emails(fecha_envio DESC);

-- ========================================
-- Triggers para updated_at
-- ========================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para trabajadores
DROP TRIGGER IF EXISTS update_trabajadores_updated_at ON trabajadores;
CREATE TRIGGER update_trabajadores_updated_at
    BEFORE UPDATE ON trabajadores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para contratistas
DROP TRIGGER IF EXISTS update_contratistas_updated_at ON contratistas;
CREATE TRIGGER update_contratistas_updated_at
    BEFORE UPDATE ON contratistas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para informes_medicos
DROP TRIGGER IF EXISTS update_informes_updated_at ON informes_medicos;
CREATE TRIGGER update_informes_updated_at
    BEFORE UPDATE ON informes_medicos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- Vistas útiles
-- ========================================

-- Vista: informes_completos
-- Combina información de trabajador, contratista e informe
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

-- Vista: informes_pendientes_ia
-- Informes que aún no han sido procesados por IA
CREATE OR REPLACE VIEW informes_pendientes_ia AS
SELECT * FROM informes_completos
WHERE procesado_por_ia = FALSE
ORDER BY fecha_examen DESC;

-- Vista: informes_alto_riesgo
-- Informes clasificados como alto riesgo
CREATE OR REPLACE VIEW informes_alto_riesgo AS
SELECT * FROM informes_completos
WHERE nivel_riesgo = 'ALTO'
ORDER BY fecha_examen DESC;

-- Vista: estadisticas_riesgo
-- Estadísticas de clasificación de riesgo
CREATE OR REPLACE VIEW estadisticas_riesgo AS
SELECT 
    nivel_riesgo,
    COUNT(*) as total,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as porcentaje
FROM informes_medicos
WHERE nivel_riesgo IS NOT NULL
GROUP BY nivel_riesgo;

-- ========================================
-- Comentarios en tablas
-- ========================================

COMMENT ON TABLE trabajadores IS 'Empleados que requieren exámenes ocupacionales';
COMMENT ON TABLE contratistas IS 'Empresas cliente que solicitan exámenes';
COMMENT ON TABLE informes_medicos IS 'Tabla central con todos los informes médicos';
COMMENT ON TABLE informes_embeddings IS 'Embeddings vectoriales para RAG con pgvector';
COMMENT ON TABLE laboratorio_resultados IS 'Resultados detallados de laboratorio';
COMMENT ON TABLE historial_emails IS 'Registro de emails enviados';

COMMENT ON COLUMN informes_medicos.origen IS 'LEGACY: del sistema legacy, EXTERNO: PDF externo procesado';
COMMENT ON COLUMN informes_medicos.nivel_riesgo IS 'Clasificación de IA: BAJO, MEDIO, ALTO';
COMMENT ON COLUMN informes_medicos.procesado_por_ia IS 'Indica si el informe fue procesado por el sistema de IA';
COMMENT ON COLUMN informes_medicos.email_message_id IS 'ID del mensaje de Amazon SES para tracking y verificación';
COMMENT ON COLUMN informes_embeddings.embedding IS 'Vector de 1024 dimensiones de Amazon Titan Embeddings v2';

-- ========================================
-- Fin del schema
-- ========================================
