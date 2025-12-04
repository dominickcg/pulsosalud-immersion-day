# Guía de Experimentación Libre - Workshop Día 2

## Introducción

Esta guía proporciona ideas y ejercicios para que explores las capacidades avanzadas de IA del Día 2 por tu cuenta. Experimenta, prueba, rompe cosas y aprende.

## Ideas para Experimentar

### 1. Modificar Prompts de Emails

#### Experimento: Cambiar el Tono de los Emails

**Objetivo**: Ver cómo diferentes prompts afectan el tono y contenido de los emails.

**Pasos**:
1. Abre `prompts/email-alto-riesgo.txt`
2. Modifica el tono (más formal, más casual, más técnico)
3. Guarda los cambios
4. Ejecuta `.\invoke-email.ps1 -InformeId 1`
5. Compara el resultado con el email original

**Variaciones para probar**:
- Tono más técnico (incluir más términos médicos)
- Tono más simple (lenguaje más accesible)
- Más empático (enfatizar apoyo emocional)
- Más directo (ir al grano rápidamente)

**Preguntas guía**:
- ¿Qué tono funciona mejor para cada nivel de riesgo?
- ¿Cómo afecta el tono a la longitud del email?
- ¿Qué tono preferirías recibir como empleado?

#### Experimento: Agregar Secciones Nuevas

**Objetivo**: Personalizar la estructura de los emails.

**Ideas**:
- Agregar sección de "Preguntas Frecuentes"
- Incluir timeline visual de seguimiento
- Agregar recursos adicionales (videos, artículos)
- Incluir testimonios motivacionales (sin violar privacidad)

### 2. Experimentar con Embeddings

#### Experimento: Comparar Similitud de Diferentes Casos

**Objetivo**: Entender qué hace que dos casos sean "similares".

**Pasos**:
1. Genera embeddings para varios informes:
   ```powershell
   1..5 | ForEach-Object { .\invoke-embeddings.ps1 -InformeId $_ }
   ```

2. Busca similares para cada uno:
   ```powershell
   1..5 | ForEach-Object { 
       Write-Host "`n=== Similares para Informe $_ ===" 
       .\test-similarity-search.ps1 -InformeId $_ 
   }
   ```

3. Analiza los resultados:
   - ¿Qué casos tienen similarity scores más altos?
   - ¿Por qué son similares?
   - ¿Hay sorpresas?

**Preguntas guía**:
- ¿Los casos con mismo tipo de examen son más similares?
- ¿Los casos con misma ocupación son más similares?
- ¿Qué pesa más: datos numéricos o texto de observaciones?

#### Experimento: Modificar el Texto de Embeddings

**Objetivo**: Ver cómo diferentes textos afectan la similitud.

**Pasos**:
1. Abre `lambda/ai/generate_embeddings/index.py`
2. Modifica la función que construye el texto para embeddings
3. Prueba diferentes combinaciones:
   - Solo observaciones
   - Solo datos numéricos
   - Observaciones + tipo de examen
   - Todo el contexto

4. Regenera embeddings y compara resultados

**Nota**: Esto requiere redesplegar la Lambda.

### 3. Experimentar con Búsqueda de Similitud

#### Experimento: Ajustar el Número de Resultados

**Objetivo**: Encontrar el número óptimo de casos similares.

**Pasos**:
```powershell
# Probar diferentes valores de TopK
.\test-similarity-search.ps1 -InformeId 1 -TopK 3
.\test-similarity-search.ps1 -InformeId 1 -TopK 5
.\test-similarity-search.ps1 -InformeId 1 -TopK 10
```

**Preguntas guía**:
- ¿Cuántos casos similares son útiles para un médico?
- ¿A partir de qué número los scores bajan mucho?
- ¿Hay un punto de rendimientos decrecientes?

#### Experimento: Filtrar por Nivel de Riesgo

**Objetivo**: Buscar solo casos similares con el mismo nivel de riesgo.

**Pasos**:
1. Modifica la query en `test-similarity-search.ps1`
2. Agrega filtro: `AND im.nivel_riesgo = 'ALTO'`
3. Compara resultados con y sin filtro

**Preguntas guía**:
- ¿Es útil filtrar por nivel de riesgo?
- ¿O es mejor ver casos similares de todos los niveles?
- ¿Qué información es más valiosa para el médico?

### 4. Experimentar con Modelos de IA

#### Experimento: Cambiar Temperatura del Modelo

**Objetivo**: Ver cómo la temperatura afecta la creatividad del modelo.

**Pasos**:
1. Abre `lambda/ai/send_email/index.py`
2. Encuentra la configuración de temperatura (actualmente 0.7)
3. Prueba diferentes valores:
   - 0.3 (más conservador, más predecible)
   - 0.7 (balanceado)
   - 0.9 (más creativo, más variado)

4. Genera emails con cada temperatura y compara

**Preguntas guía**:
- ¿Qué temperatura genera emails más apropiados?
- ¿Hay diferencia notable entre temperaturas?
- ¿Qué temperatura preferirías para emails médicos?

#### Experimento: Probar Diferentes Modelos

**Objetivo**: Comparar modelos de Bedrock.

**Modelos disponibles**:
- Claude 3 Sonnet
- Claude 3.5 Sonnet
- Nova Pro (actual)
- Nova Lite

**Pasos**:
1. Modifica el model ID en la Lambda
2. Redesplega
3. Genera emails con cada modelo
4. Compara calidad, velocidad y costo

### 5. Experimentar con Queries SQL

#### Experimento: Crear Queries Personalizadas

**Objetivo**: Explorar los datos de diferentes maneras.

**Ideas de queries**:

```sql
-- 1. Distribución de niveles de riesgo por tipo de examen
SELECT 
    tipo_examen,
    nivel_riesgo,
    COUNT(*) as total
FROM informes_medicos
WHERE nivel_riesgo IS NOT NULL
GROUP BY tipo_examen, nivel_riesgo
ORDER BY tipo_examen, nivel_riesgo;

-- 2. Promedio de similarity scores por tipo de examen
SELECT 
    im.tipo_examen,
    AVG(1 - (ie1.embedding <=> ie2.embedding)) as avg_similarity
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
CROSS JOIN informes_embeddings ie2
WHERE im.id != ie2.informe_id
GROUP BY im.tipo_examen;

-- 3. Casos con mayor variabilidad en similarity
SELECT 
    im.id,
    im.trabajador_nombre,
    MAX(1 - (ie1.embedding <=> ie2.embedding)) as max_sim,
    MIN(1 - (ie1.embedding <=> ie2.embedding)) as min_sim,
    MAX(1 - (ie1.embedding <=> ie2.embedding)) - 
    MIN(1 - (ie1.embedding <=> ie2.embedding)) as variability
FROM informes_medicos im
JOIN informes_embeddings ie1 ON im.id = ie1.informe_id
CROSS JOIN informes_embeddings ie2
WHERE im.id != ie2.informe_id
GROUP BY im.id, im.trabajador_nombre
ORDER BY variability DESC;
```

### 6. Experimentar con Privacidad

#### Experimento: Validar que Emails No Violan Privacidad

**Objetivo**: Asegurar que los emails generados respetan privacidad.

**Checklist de validación**:
```powershell
# Generar varios emails
1..10 | ForEach-Object {
    Write-Host "`n=== Email para Informe $_ ==="
    .\invoke-email.ps1 -InformeId $_
    
    # Revisar manualmente:
    # - ¿Menciona otros empleados? ❌
    # - ¿Dice "casos similares"? ❌
    # - ¿Solo datos del empleado actual? ✅
}
```

**Preguntas guía**:
- ¿Algún email menciona información de terceros?
- ¿Los prompts son suficientemente claros sobre privacidad?
- ¿Hay formas de mejorar los prompts?

## Ejercicios Guiados

### Ejercicio 1: Pipeline Completo

**Objetivo**: Ejecutar el flujo completo de procesamiento.

**Pasos**:
```powershell
# 1. Seleccionar un informe
$INFORME_ID = 1

# 2. Clasificar
.\invoke-classify.ps1 -InformeId $INFORME_ID

# 3. Generar resumen
.\invoke-summary.ps1 -InformeId $INFORME_ID

# 4. Generar embedding
.\invoke-embeddings.ps1 -InformeId $INFORME_ID

# 5. Buscar similares
.\test-similarity-search.ps1 -InformeId $INFORME_ID

# 6. Generar email
.\invoke-email.ps1 -InformeId $INFORME_ID
```

**Preguntas de reflexión**:
- ¿Cuánto tiempo tomó todo el proceso?
- ¿Qué paso fue más lento?
- ¿Cómo se podría optimizar?

### Ejercicio 2: Comparación A/B de Prompts

**Objetivo**: Comparar dos versiones de un prompt.

**Pasos**:
1. Crea una copia del prompt original:
   ```powershell
   Copy-Item prompts/email-alto-riesgo.txt prompts/email-alto-riesgo-v2.txt
   ```

2. Modifica la versión 2 con cambios específicos

3. Genera emails con ambas versiones:
   ```powershell
   # Versión 1
   .\invoke-email.ps1 -InformeId 1 > email-v1.txt
   
   # Cambiar prompt en Lambda a v2 y redesplegar
   
   # Versión 2
   .\invoke-email.ps1 -InformeId 1 > email-v2.txt
   ```

4. Compara resultados:
   ```powershell
   code --diff email-v1.txt email-v2.txt
   ```

### Ejercicio 3: Análisis de Clusters

**Objetivo**: Identificar grupos de casos similares.

**Pasos**:
1. Genera embeddings para todos los informes
2. Calcula matriz de similitud completa
3. Identifica clusters (grupos de casos muy similares)
4. Analiza qué tienen en común

**Query de ejemplo**:
```sql
-- Pares de informes con alta similitud (>0.9)
SELECT 
    im1.id as informe1,
    im2.id as informe2,
    t1.nombre as trabajador1,
    t2.nombre as trabajador2,
    im1.tipo_examen,
    1 - (ie1.embedding <=> ie2.embedding) as similarity
FROM informes_medicos im1
JOIN informes_embeddings ie1 ON im1.id = ie1.informe_id
JOIN trabajadores t1 ON im1.trabajador_id = t1.id
CROSS JOIN informes_medicos im2
JOIN informes_embeddings ie2 ON im2.id = ie2.informe_id
JOIN trabajadores t2 ON im2.trabajador_id = t2.id
WHERE im1.id < im2.id
  AND 1 - (ie1.embedding <=> ie2.embedding) > 0.9
ORDER BY similarity DESC;
```

## Preguntas de Exploración

### Sobre Embeddings

1. ¿Qué tan sensibles son los embeddings a cambios pequeños en el texto?
2. ¿Los embeddings capturan mejor información numérica o textual?
3. ¿Cómo afecta la longitud del texto a la calidad del embedding?
4. ¿Hay casos donde embeddings dan resultados inesperados?

### Sobre Búsqueda de Similitud

1. ¿Qué threshold de similitud es apropiado? (0.7, 0.8, 0.9?)
2. ¿Es mejor buscar muchos casos con baja similitud o pocos con alta?
3. ¿Cómo manejar casos donde no hay similares (similarity < 0.5)?
4. ¿Deberíamos filtrar por fecha (solo casos recientes)?

### Sobre Generación de Emails

1. ¿Qué longitud de email es óptima?
2. ¿Deberíamos incluir más o menos detalles técnicos?
3. ¿Cómo balancear información vs. simplicidad?
4. ¿Qué secciones son más importantes para los empleados?

### Sobre Privacidad

1. ¿Hay formas sutiles de violar privacidad que no son obvias?
2. ¿Cómo asegurar que prompts futuros respeten privacidad?
3. ¿Deberíamos auditar emails generados automáticamente?
4. ¿Qué controles adicionales se podrían implementar?

## Recursos Adicionales

### Documentación

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)

### Herramientas

- **AWS CloudWatch**: Ver logs de Lambdas
- **RDS Query Editor**: Ejecutar queries SQL
- **VS Code**: Editar prompts y código

### Scripts Útiles

```powershell
# Ver logs en tiempo real
.\view-logs.ps1

# Ejecutar query personalizada
aws rds-data execute-statement `
  --resource-arn $env:CLUSTER_ARN `
  --secret-arn $env:SECRET_ARN `
  --database $env:DATABASE_NAME `
  --sql "TU_QUERY_AQUI"

# Listar todas las Lambdas
aws lambda list-functions `
  --query 'Functions[?contains(FunctionName, `'$env:PARTICIPANT_PREFIX'`)].FunctionName'
```

## Desafíos Avanzados

### Desafío 1: Optimizar Performance

**Objetivo**: Reducir el tiempo de procesamiento del pipeline completo.

**Ideas**:
- Procesar embeddings en paralelo
- Cachear resultados de búsqueda
- Optimizar queries SQL
- Usar índices más eficientes

### Desafío 2: Mejorar Calidad de Emails

**Objetivo**: Generar emails más personalizados y efectivos.

**Ideas**:
- Incluir historial del trabajador
- Adaptar lenguaje según educación/rol
- Agregar visualizaciones (gráficos de tendencias)
- Incluir comparación con exámenes previos

### Desafío 3: Implementar Validación Automática

**Objetivo**: Detectar automáticamente violaciones de privacidad.

**Ideas**:
- Crear función que analiza emails generados
- Buscar patrones prohibidos (nombres, "casos similares", etc.)
- Implementar sistema de alertas
- Crear dashboard de métricas de privacidad

### Desafío 4: Análisis de Patrones Ocupacionales

**Objetivo**: Identificar riesgos por tipo de trabajo.

**Ideas**:
- Agrupar informes por ocupación
- Calcular riesgos promedio por ocupación
- Identificar patrones de salud ocupacional
- Generar recomendaciones preventivas por ocupación

## Conclusión

La experimentación es clave para entender profundamente estas tecnologías. No tengas miedo de:

- Romper cosas (puedes redesplegar)
- Probar ideas locas
- Hacer preguntas
- Compartir descubrimientos con otros participantes

**Recuerda**: El objetivo es aprender, no tener todo perfecto.

## Comparte tus Descubrimientos

Si encuentras algo interesante:
1. Documenta qué hiciste
2. Anota los resultados
3. Comparte con el instructor y otros participantes
4. Considera contribuir mejoras al proyecto

¡Feliz experimentación! 🚀
