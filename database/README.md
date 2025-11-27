# Database Scripts

Scripts SQL para crear y poblar la base de datos Aurora PostgreSQL con extensión pgvector.

## Archivos

- `schema.sql` - Schema completo de la base de datos
- `seed_data.sql` - Datos de ejemplo para testing y demo

## Ejecución

### Opción 1: Usando RDS Data API (Recomendado)

```bash
# Ejecutar schema
aws rds-data execute-statement \
  --resource-arn "arn:aws:rds:region:account:cluster:cluster-name" \
  --secret-arn "arn:aws:secretsmanager:region:account:secret:secret-name" \
  --database "medical_reports" \
  --sql "$(cat schema.sql)"

# Ejecutar seed data
aws rds-data execute-statement \
  --resource-arn "arn:aws:rds:region:account:cluster:cluster-name" \
  --secret-arn "arn:aws:secretsmanager:region:account:secret:secret-name" \
  --database "medical_reports" \
  --sql "$(cat seed_data.sql)"
```

### Opción 2: Usando psql

```bash
# Conectar a Aurora
psql -h cluster-endpoint.region.rds.amazonaws.com \
     -U postgres \
     -d medical_reports

# Ejecutar scripts
\i schema.sql
\i seed_data.sql
```

### Opción 3: Durante el despliegue de CDK

El schema se puede ejecutar automáticamente durante el despliegue usando un Custom Resource de CDK.

## Schema Overview

### Tablas Principales

1. **trabajadores** - Empleados que requieren exámenes
   - Campos: nombre, documento, fecha_nacimiento, genero, puesto
   - Índices: documento (unique), nombre

2. **contratistas** - Empresas cliente
   - Campos: nombre, email, telefono, direccion
   - Índices: email, nombre

3. **informes_medicos** - Tabla central de informes
   - Campos: tipo_examen, fecha_examen, signos vitales, observaciones
   - Campos IA: nivel_riesgo, justificacion_riesgo, resumen_ejecutivo
   - Auditoría: procesado_por_ia, email_enviado
   - Índices: trabajador_id, fecha_examen, nivel_riesgo, procesado_por_ia

4. **informes_embeddings** - Embeddings para RAG
   - Campos: embedding (vector 1536), contenido, fecha_examen
   - Índice: IVFFlat para búsqueda de similitud con pgvector
   - Índices: trabajador_id, informe_id

5. **laboratorio_resultados** - Resultados de laboratorio
   - Campos: hematología, perfil lipídico, glucosa, función renal/hepática
   - Índice: informe_id

6. **historial_emails** - Registro de emails enviados
   - Campos: destinatario, asunto, cuerpo, estado
   - Índices: informe_id, estado, fecha_envio

### Vistas

- **informes_completos** - Join de informes con trabajador y contratista
- **informes_pendientes_ia** - Informes sin procesar por IA
- **informes_alto_riesgo** - Informes clasificados como alto riesgo
- **estadisticas_riesgo** - Estadísticas de clasificación

### Extensiones

- **pgvector** - Para almacenar y buscar embeddings vectoriales

### Triggers

- **update_updated_at_column** - Actualiza automáticamente el campo updated_at

## Datos de Seed

El archivo `seed_data.sql` incluye:

- 5 contratistas de ejemplo
- 10 trabajadores de ejemplo
- 5 informes médicos (3 procesados, 2 pendientes)
- 3 resultados de laboratorio
- 3 emails enviados

### Niveles de Riesgo en Seed Data

- **Informe 1**: BAJO - Valores normales
- **Informe 2**: MEDIO - Valores límite
- **Informe 3**: ALTO - Hipertensión severa
- **Informes 4-5**: Pendientes de procesar

## Consultas Útiles

```sql
-- Ver todos los informes con información completa
SELECT * FROM informes_completos ORDER BY fecha_examen DESC;

-- Ver informes pendientes de procesar
SELECT * FROM informes_pendientes_ia;

-- Ver informes de alto riesgo
SELECT * FROM informes_alto_riesgo;

-- Ver estadísticas de riesgo
SELECT * FROM estadisticas_riesgo;

-- Buscar informes similares usando pgvector
SELECT 
    ie.informe_id,
    ie.contenido,
    ie.embedding <=> '[0.1, 0.2, ...]'::vector AS distance
FROM informes_embeddings ie
WHERE ie.trabajador_id = 1
ORDER BY distance
LIMIT 3;

-- Ver conteo por origen
SELECT origen, COUNT(*) as total 
FROM informes_medicos 
GROUP BY origen;

-- Ver conteo por nivel de riesgo
SELECT nivel_riesgo, COUNT(*) as total 
FROM informes_medicos 
WHERE nivel_riesgo IS NOT NULL 
GROUP BY nivel_riesgo;
```

## Notas Importantes

### pgvector

- La extensión pgvector debe estar habilitada antes de crear las tablas
- Los embeddings son vectores de 1536 dimensiones (Amazon Titan Embeddings v2)
- El índice IVFFlat permite búsquedas aproximadas rápidas
- El operador `<=>` calcula la distancia coseno entre vectores

### Índices

- Los índices están optimizados para las consultas más comunes
- El índice IVFFlat en embeddings usa 100 listas (ajustable según volumen de datos)
- Los índices en campos de auditoría facilitan el monitoreo del sistema

### Cascadas

- Las foreign keys tienen `ON DELETE CASCADE` para mantener integridad referencial
- Al eliminar un trabajador, se eliminan sus informes y embeddings
- Al eliminar un informe, se eliminan sus embeddings y resultados de laboratorio

### Timestamps

- Todas las tablas tienen `created_at` y `updated_at`
- Los triggers actualizan automáticamente `updated_at` en cada UPDATE
- Los timestamps usan zona horaria del servidor

## Mantenimiento

### Vacuum y Analyze

```sql
-- Ejecutar periódicamente para optimizar rendimiento
VACUUM ANALYZE informes_medicos;
VACUUM ANALYZE informes_embeddings;
```

### Reindexar pgvector

```sql
-- Si el volumen de datos crece significativamente
REINDEX INDEX idx_embedding_vector;
```

### Limpiar datos antiguos

```sql
-- Eliminar informes de más de 2 años (ejemplo)
DELETE FROM informes_medicos 
WHERE fecha_examen < NOW() - INTERVAL '2 years';
```

## Troubleshooting

### Error: "extension vector does not exist"

```sql
-- Habilitar la extensión manualmente
CREATE EXTENSION vector;
```

### Error: "operator does not exist: vector <=> vector"

- Verificar que pgvector esté correctamente instalado
- Reiniciar la conexión a la base de datos

### Rendimiento lento en búsquedas de similitud

- Aumentar el número de listas en el índice IVFFlat
- Considerar usar HNSW en lugar de IVFFlat para datasets grandes
- Ejecutar VACUUM ANALYZE en la tabla de embeddings
