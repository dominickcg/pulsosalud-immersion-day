-- ============================================================================
-- SQL Queries para Verificación - Medical Reports Workshop
-- ============================================================================
-- INSTRUCCIONES:
-- 1. Reemplaza "participant-X" con tu prefijo asignado en los comandos AWS CLI
-- 2. Copia y pega las queries que necesites
-- 3. Ejecuta usando RDS Data API (ver ejemplos al final)
-- ============================================================================

-- ============================================================================
-- QUERIES DE VERIFICACIÓN BÁSICA
-- ============================================================================

-- 1. Verificar que las tablas existen
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Contar registros en cada tabla
SELECT 
    'trabajadores' as tabla, COUNT(*) as total FROM trabajadores
UNION ALL
SELECT 
    'contratistas' as tabla, COUNT(*) as total FROM contratistas
UNION ALL
SELECT 
    'informes_medicos' as tabla, COUNT(*) as total FROM informes_medicos;

-- ============================================================================
-- QUERIES PARA TRABAJADORES
-- ============================================================================

-- 3. Ver todos los trabajadores
SELECT 
    id,
    nombre,
    edad,
    puesto,
    created_at
FROM trabajadores
ORDER BY id;

-- 4. Ver trabajadores con su contratista
SELECT 
    t.id,
    t.nombre as trabajador,
    c.nombre as contratista,
    t.puesto
FROM trabajadores t
JOIN contratistas c ON t.contratista_id = c.id
ORDER BY t.id;

-- ============================================================================
-- QUERIES PARA INFORMES MÉDICOS
-- ============================================================================

-- 5. Ver todos los informes con información básica
SELECT 
    i.id,
    t.nombre as trabajador,
    i.tipo_examen,
    i.presion_arterial,
    i.nivel_riesgo,
    i.fecha_examen
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
ORDER BY i.fecha_examen DESC;

-- 6. Ver informes clasificados (con nivel de riesgo)
SELECT 
    i.id,
    t.nombre as trabajador,
    i.tipo_examen,
    i.nivel_riesgo,
    i.justificacion_riesgo,
    i.fecha_examen
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
WHERE i.nivel_riesgo IS NOT NULL
ORDER BY i.fecha_examen DESC;

-- 7. Ver informes con resumen ejecutivo
SELECT 
    i.id,
    t.nombre as trabajador,
    i.nivel_riesgo,
    i.resumen_ejecutivo,
    i.fecha_examen
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
WHERE i.resumen_ejecutivo IS NOT NULL
ORDER BY i.fecha_examen DESC;

-- 8. Contar informes por nivel de riesgo
SELECT 
    nivel_riesgo,
    COUNT(*) as total
FROM informes_medicos
WHERE nivel_riesgo IS NOT NULL
GROUP BY nivel_riesgo
ORDER BY 
    CASE nivel_riesgo
        WHEN 'ALTO' THEN 1
        WHEN 'MEDIO' THEN 2
        WHEN 'BAJO' THEN 3
    END;

-- ============================================================================
-- QUERIES PARA ANÁLISIS DE DATOS
-- ============================================================================

-- 9. Ver historial médico de un trabajador específico
-- (Reemplaza el ID con el trabajador que quieres consultar)
SELECT 
    i.id,
    i.tipo_examen,
    i.presion_arterial,
    i.peso,
    i.altura,
    i.nivel_riesgo,
    i.fecha_examen
FROM informes_medicos i
WHERE i.trabajador_id = 1  -- Cambiar el ID según necesites
ORDER BY i.fecha_examen DESC;

-- 10. Ver informes pendientes de clasificación
SELECT 
    i.id,
    t.nombre as trabajador,
    i.tipo_examen,
    i.presion_arterial,
    i.fecha_examen
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
WHERE i.nivel_riesgo IS NULL
ORDER BY i.fecha_examen DESC;

-- 11. Ver informes clasificados pero sin resumen
SELECT 
    i.id,
    t.nombre as trabajador,
    i.tipo_examen,
    i.nivel_riesgo,
    i.fecha_examen
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
WHERE i.nivel_riesgo IS NOT NULL 
  AND i.resumen_ejecutivo IS NULL
ORDER BY i.fecha_examen DESC;

-- 12. Ver estadísticas completas por trabajador
SELECT 
    t.nombre as trabajador,
    COUNT(i.id) as total_informes,
    COUNT(CASE WHEN i.nivel_riesgo = 'ALTO' THEN 1 END) as riesgo_alto,
    COUNT(CASE WHEN i.nivel_riesgo = 'MEDIO' THEN 1 END) as riesgo_medio,
    COUNT(CASE WHEN i.nivel_riesgo = 'BAJO' THEN 1 END) as riesgo_bajo,
    MAX(i.fecha_examen) as ultimo_examen
FROM trabajadores t
LEFT JOIN informes_medicos i ON t.id = i.trabajador_id
GROUP BY t.id, t.nombre
ORDER BY total_informes DESC;

-- ============================================================================
-- QUERIES PARA RAG Y EMBEDDINGS (DÍA 2)
-- ============================================================================

-- 13. Verificar que la extensión pgvector está habilitada
SELECT * FROM pg_extension WHERE extname = 'vector';

-- 14. Ver informes con embeddings generados
SELECT 
    ie.id,
    ie.informe_id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.fecha_examen,
    ie.created_at as embedding_creado
FROM informes_embeddings ie
JOIN informes_medicos im ON ie.informe_id = im.id
JOIN trabajadores t ON im.trabajador_id = t.id
ORDER BY ie.created_at DESC;

-- 15. Contar informes con y sin embeddings
SELECT 
    'Con embeddings' as estado, COUNT(*) as total
FROM informes_medicos im
WHERE EXISTS (
    SELECT 1 FROM informes_embeddings ie 
    WHERE ie.informe_id = im.id
)
UNION ALL
SELECT 
    'Sin embeddings' as estado, COUNT(*) as total
FROM informes_medicos im
WHERE NOT EXISTS (
    SELECT 1 FROM informes_embeddings ie 
    WHERE ie.informe_id = im.id
);

-- 16. Buscar informes similares usando embeddings
-- (Reemplaza el ID con el informe de referencia)
-- Esta query encuentra los 5 informes más similares al informe especificado
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    im.fecha_examen,
    1 - (ie1.embedding <=> ie2.embedding) as similarity_score
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
JOIN trabajadores t ON im.trabajador_id = t.id
CROSS JOIN informes_embeddings ie2
WHERE ie2.informe_id = 1  -- Cambiar el ID del informe de referencia
  AND im.id != 1  -- Excluir el informe actual
ORDER BY similarity_score DESC
LIMIT 5;

-- 17. Ver contenido de texto usado para embeddings
SELECT 
    ie.informe_id,
    t.nombre as trabajador,
    LEFT(ie.contenido, 200) as preview_contenido,
    LENGTH(ie.contenido) as longitud_texto,
    ie.created_at
FROM informes_embeddings ie
JOIN informes_medicos im ON ie.informe_id = im.id
JOIN trabajadores t ON im.trabajador_id = t.id
ORDER BY ie.created_at DESC;

-- 18. Estadísticas de embeddings por tipo de examen
SELECT 
    im.tipo_examen,
    COUNT(ie.id) as total_embeddings,
    AVG(LENGTH(ie.contenido)) as promedio_longitud_texto
FROM informes_medicos im
LEFT JOIN informes_embeddings ie ON im.id = ie.informe_id
GROUP BY im.tipo_examen
ORDER BY total_embeddings DESC;

-- ============================================================================
-- QUERIES PARA EMAILS (DÍA 2)
-- ============================================================================

-- 19. Ver informes con emails enviados
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    im.email_enviado,
    im.fecha_email_enviado,
    im.email_message_id
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
WHERE im.email_enviado = TRUE
ORDER BY im.fecha_email_enviado DESC;

-- 20. Contar emails enviados por nivel de riesgo
SELECT 
    nivel_riesgo,
    COUNT(*) as emails_enviados
FROM informes_medicos
WHERE email_enviado = TRUE
GROUP BY nivel_riesgo
ORDER BY 
    CASE nivel_riesgo
        WHEN 'ALTO' THEN 1
        WHEN 'MEDIO' THEN 2
        WHEN 'BAJO' THEN 3
    END;

-- 21. Ver historial completo de emails
SELECT 
    he.id,
    he.informe_id,
    t.nombre as trabajador,
    he.destinatario,
    he.asunto,
    he.estado,
    he.fecha_envio,
    he.mensaje_error
FROM historial_emails he
JOIN informes_medicos im ON he.informe_id = im.id
JOIN trabajadores t ON im.trabajador_id = t.id
ORDER BY he.fecha_envio DESC;

-- 22. Ver informes listos para enviar email (clasificados pero sin email)
SELECT 
    im.id,
    t.nombre as trabajador,
    im.tipo_examen,
    im.nivel_riesgo,
    im.fecha_examen
FROM informes_medicos im
JOIN trabajadores t ON im.trabajador_id = t.id
WHERE im.nivel_riesgo IS NOT NULL
  AND im.email_enviado = FALSE
ORDER BY im.fecha_examen DESC;

-- ============================================================================
-- QUERIES PARA DEBUGGING
-- ============================================================================

-- 23. Ver un informe específico con todos sus detalles
-- (Reemplaza el ID con el informe que quieres consultar)
SELECT 
    i.*,
    t.nombre as trabajador_nombre,
    c.nombre as contratista_nombre
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
JOIN contratistas c ON t.contratista_id = c.id
WHERE i.id = 1;  -- Cambiar el ID según necesites

-- 24. Ver últimos 5 informes procesados
SELECT 
    i.id,
    t.nombre as trabajador,
    i.tipo_examen,
    i.nivel_riesgo,
    CASE 
        WHEN i.resumen_ejecutivo IS NOT NULL THEN 'Sí'
        ELSE 'No'
    END as tiene_resumen,
    i.fecha_examen,
    i.updated_at
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
ORDER BY i.updated_at DESC
LIMIT 5;

-- ============================================================================
-- CÓMO EJECUTAR ESTAS QUERIES USANDO AWS CLI
-- ============================================================================

-- IMPORTANTE: Reemplaza "participant-X" con tu prefijo asignado

-- Opción 1: Ejecutar una query directamente
-- aws rds-data execute-statement \
--   --resource-arn "arn:aws:rds:us-east-2:ACCOUNT:cluster:participant-X-aurora-cluster" \
--   --secret-arn "arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:participant-X-aurora-secret" \
--   --database "medical_reports" \
--   --sql "SELECT * FROM trabajadores"

-- Opción 2: Ejecutar una query desde un archivo
-- aws rds-data execute-statement \
--   --resource-arn "arn:aws:rds:us-east-2:ACCOUNT:cluster:participant-X-aurora-cluster" \
--   --secret-arn "arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:participant-X-aurora-secret" \
--   --database "medical_reports" \
--   --sql file://query.sql

-- Opción 3: Usar variables de entorno (después de ejecutar setup-env-vars.ps1)
-- aws rds-data execute-statement \
--   --resource-arn $env:CLUSTER_ARN \
--   --secret-arn $env:SECRET_ARN \
--   --database $env:DATABASE_NAME \
--   --sql "SELECT COUNT(*) FROM informes_medicos"

-- ============================================================================
-- TIPS ÚTILES
-- ============================================================================

-- 💡 Para obtener los ARNs necesarios:
--    .\setup-env-vars.ps1

-- 💡 Para ver los resultados en formato más legible:
--    Agrega --output table al final del comando AWS CLI

-- 💡 Los logs de las queries se pueden ver en CloudWatch:
--    aws logs tail /aws/rds/cluster/participant-X-aurora-cluster/postgresql --follow

-- 💡 Para queries complejas, guárdalas en un archivo .sql y usa file://
