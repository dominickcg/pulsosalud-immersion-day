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
-- QUERIES PARA DEBUGGING
-- ============================================================================

-- 13. Ver un informe específico con todos sus detalles
-- (Reemplaza el ID con el informe que quieres consultar)
SELECT 
    i.*,
    t.nombre as trabajador_nombre,
    c.nombre as contratista_nombre
FROM informes_medicos i
JOIN trabajadores t ON i.trabajador_id = t.id
JOIN contratistas c ON t.contratista_id = c.id
WHERE i.id = 1;  -- Cambiar el ID según necesites

-- 14. Ver últimos 5 informes procesados
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
