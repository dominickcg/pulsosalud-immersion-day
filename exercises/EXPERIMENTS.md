# 🧪 Ejercicios Prácticos de Experimentación

Esta guía contiene ejercicios prácticos para experimentar con prompts, parámetros y técnicas de IA Generativa en el workshop de Medical Reports Automation.

## 🎯 Objetivos

Al completar estos ejercicios, aprenderás a:
- Ajustar parámetros de modelos (temperature, maxTokens)
- Iterar y mejorar prompts
- Comparar resultados con y sin RAG
- Modificar tonos y estilos de contenido
- Medir el impacto de cambios en la calidad

---

## 📚 Ejercicio 1: Experimentar con Temperature en Extracción

### Objetivo
Entender cómo la temperature afecta la consistencia y precisión en tareas de extracción de datos.

### Contexto
La **temperature** controla la aleatoriedad del modelo:
- **0.0 - 0.2**: Determinístico, siempre da respuestas similares
- **0.8 - 1.0**: Creativo, respuestas muy variadas

Para extracción de datos, queremos consistencia (temperature baja).

### Pasos

#### 1. Configuración Inicial (Temperature 0.1)

Verifica la configuración actual en `lambda/ai/extract_pdf/index.py`:

```python
"inferenceConfig": {
    "temperature": 0.1,  # ← Valor actual
    "maxTokens": 2000
}
```

#### 2. Subir PDF de Prueba

```bash
bash scripts/upload_sample_pdf.sh sample_data/informe_medio_riesgo.pdf <bucket-name>
```

#### 3. Verificar Resultado

```bash
# Ver logs
aws logs tail /aws/lambda/extract-pdf --follow

# Consultar datos extraídos
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT trabajador_nombre, presion_arterial, peso FROM informes_medicos WHERE id = (SELECT MAX(id) FROM informes_medicos);"
```

Anota los resultados.

#### 4. Cambiar Temperature a 0.8

Edita `lambda/ai/extract_pdf/index.py`:

```python
"inferenceConfig": {
    "temperature": 0.8,  # ← Cambiar a 0.8
    "maxTokens": 2000
}
```

#### 5. Re-desplegar

```bash
cd cdk
cdk deploy AIExtractionStack
```

#### 6. Subir el Mismo PDF Otra Vez

```bash
# Renombrar para que se procese de nuevo
aws s3 cp sample_data/informe_medio_riesgo.pdf \
  s3://<bucket-name>/external-reports/informe_medio_riesgo_test2.pdf
```

#### 7. Comparar Resultados

```bash
# Ver últimos 2 registros
psql -h <endpoint> -U postgres -d medical_reports \
  -c "SELECT id, trabajador_nombre, presion_arterial, peso FROM informes_medicos ORDER BY id DESC LIMIT 2;"
```

### Preguntas para Reflexionar

1. ¿Los datos extraídos son idénticos con temperature 0.1 y 0.8?
2. ¿Cuál configuración es más consistente?
3. ¿Por qué es importante la consistencia en extracción de datos?

### Resultado Esperado

- **Temperature 0.1**: Datos idénticos en múltiples extracciones
- **Temperature 0.8**: Puede haber variaciones en formato o valores

### Conclusión

Para extracción de datos estructurados, usa **temperature baja (0.1-0.2)** para garantizar consistencia.

---


## 📚 Ejercicio 2: Ajustar maxTokens en Resúmenes

### Objetivo
Entender cómo maxTokens afecta la longitud y completitud de las respuestas.

### Contexto
**maxTokens** limita la longitud máxima de la respuesta del modelo:
- Muy bajo: Respuestas cortadas
- Muy alto: Respuestas verbosas
- Justo: Respuestas completas y concisas

### Pasos

#### 1. Configuración Inicial (maxTokens 300)

Verifica en `lambda/ai/generate_summary/index.py`:

```python
"inferenceConfig": {
    "temperature": 0.5,
    "maxTokens": 300  # ← Valor actual
}
```

#### 2. Generar Resumen

```bash
aws lambda invoke \
  --function-name generate-summary \
  --payload '{"informe_id": 1}' \
  response.json

cat response.json
```

Anota la longitud del resumen (cuenta palabras).

#### 3. Cambiar maxTokens a 100

Edita `lambda/ai/generate_summary/index.py`:

```python
"inferenceConfig": {
    "temperature": 0.5,
    "maxTokens": 100  # ← Cambiar a 100
}
```

#### 4. Re-desplegar

```bash
cd cdk
cdk deploy AISummaryStack
```

#### 5. Generar Resumen con Límite Bajo

```bash
# Actualizar el mismo informe
aws lambda invoke \
  --function-name generate-summary \
  --payload '{"informe_id": 1}' \
  response.json

cat response.json
```

#### 6. Cambiar maxTokens a 1000

```python
"inferenceConfig": {
    "temperature": 0.5,
    "maxTokens": 1000  # ← Cambiar a 1000
}
```

Re-desplegar y generar resumen nuevamente.

### Comparación

| maxTokens | Longitud | Completitud | Observaciones |
|-----------|----------|-------------|---------------|
| 100 | ~50-70 palabras | Incompleto | Se corta a mitad |
| 300 | ~120-150 palabras | Completo | Balance ideal |
| 1000 | ~150-200 palabras | Completo | Puede ser verboso |

### Preguntas para Reflexionar

1. ¿Qué pasa cuando maxTokens es muy bajo?
2. ¿El modelo usa todos los tokens disponibles?
3. ¿Cuál es el balance ideal para resúmenes ejecutivos?

### Resultado Esperado

- **maxTokens 100**: Resumen cortado, información incompleta
- **maxTokens 300**: Resumen completo y conciso
- **maxTokens 1000**: Resumen completo, posiblemente con información redundante

### Conclusión

Ajusta maxTokens según la tarea:
- Resúmenes cortos: 200-300 tokens
- Resúmenes detallados: 500-800 tokens
- Análisis completos: 1000-2000 tokens

---

## 📚 Ejercicio 3: Mejorar Few-Shot Learning en Clasificación

### Objetivo
Ver cómo agregar más ejemplos mejora la precisión de clasificación.

### Contexto
**Few-shot learning** usa ejemplos en el prompt para enseñar al modelo. Más ejemplos (hasta cierto punto) = mejor precisión.

### Pasos

#### 1. Versión Actual (3 ejemplos)

Revisa `prompts/classification.txt`. Actualmente tiene 3 ejemplos (BAJO, MEDIO, ALTO).

#### 2. Clasificar Varios Informes

```bash
# Generar 5 informes de prueba
for i in {1..5}; do
  aws lambda invoke \
    --function-name generate-test-data \
    --payload '{}' \
    response.json
done

# Clasificar todos
for i in {1..5}; do
  aws lambda invoke \
    --function-name classify-risk \
    --payload "{\"informe_id\": $i}" \
    response.json
  
  echo "Informe $i:"
  cat response.json
  echo ""
done
```

Anota la precisión de las clasificaciones.

#### 3. Agregar Más Ejemplos

Edita `prompts/classification.txt` y agrega 2 ejemplos más:

```
EJEMPLOS:

[Ejemplo BAJO 1]
...

[Ejemplo BAJO 2 - NUEVO]
Trabajador: Ana Martínez
Presión: 115/72 mmHg
IMC: 22.1
Colesterol: 175 mg/dL
Glucosa: 88 mg/dL
Clasificación: BAJO
Justificación: Todos los parámetros óptimos. Trabajadora joven y saludable...

[Ejemplo MEDIO 1]
...

[Ejemplo MEDIO 2 - NUEVO]
Trabajador: Roberto Silva
Presión: 138/86 mmHg
IMC: 26.8
Colesterol: 208 mg/dL
Clasificación: MEDIO
Justificación: Presión arterial en límite superior. Sobrepeso leve...

[Ejemplo ALTO 1]
...

[Ejemplo ALTO 2 - NUEVO]
Trabajador: Patricia Gómez
Presión: 160/98 mmHg
IMC: 33.5
Glucosa: 152 mg/dL
Colesterol: 245 mg/dL
Clasificación: ALTO
Justificación: Hipertensión grado 2, obesidad, hiperglucemia...
```

#### 4. Re-desplegar

```bash
cd cdk
cdk deploy AIClassificationStack
```

#### 5. Clasificar los Mismos Informes

```bash
# Reclasificar
for i in {1..5}; do
  aws lambda invoke \
    --function-name classify-risk \
    --payload "{\"informe_id\": $i}" \
    response.json
  
  echo "Informe $i (con más ejemplos):"
  cat response.json
  echo ""
done
```

### Comparación

| Configuración | Precisión | Justificaciones | Observaciones |
|---------------|-----------|-----------------|---------------|
| 3 ejemplos | ~70-80% | Genéricas | Funciona pero puede mejorar |
| 6 ejemplos | ~85-95% | Más específicas | Mejor comprensión de matices |

### Preguntas para Reflexionar

1. ¿Las clasificaciones son más precisas con más ejemplos?
2. ¿Las justificaciones son más detalladas?
3. ¿Hay un punto donde más ejemplos no ayudan?

### Resultado Esperado

- **3 ejemplos**: Clasificación funcional pero básica
- **6 ejemplos**: Clasificación más precisa y justificaciones detalladas
- **10+ ejemplos**: Mejora marginal (rendimientos decrecientes)

### Conclusión

Para few-shot learning:
- **Mínimo**: 1-2 ejemplos por categoría
- **Óptimo**: 2-3 ejemplos por categoría
- **Máximo útil**: 5 ejemplos por categoría

---


## 📚 Ejercicio 4: Modificar Tono en Emails

### Objetivo
Aprender a controlar el tono y estilo del contenido generado mediante prompts.

### Contexto
El mismo dato puede comunicarse con diferentes tonos según la audiencia y urgencia. Los prompts permiten controlar esto.

### Pasos

#### 1. Tono Actual (Urgente para ALTO riesgo)

Revisa `prompts/email_high.txt`:

```
Genera un email URGENTE para el contratista.

TONO: Urgente pero profesional
OBJETIVO: Acción inmediata

Incluye:
- Hallazgos críticos destacados
- Acciones requeridas INMEDIATAMENTE
- Consecuencias de no actuar
```

#### 2. Enviar Email con Tono Urgente

```bash
# Asegúrate de tener un informe de ALTO riesgo
aws lambda invoke \
  --function-name send-email \
  --payload '{"informe_id": 1}' \
  response.json
```

Revisa el email recibido. Anota el tono y lenguaje usado.

#### 3. Cambiar a Tono Profesional Tranquilizador

Edita `prompts/email_high.txt`:

```
Genera un email PROFESIONAL para el contratista.

TONO: Profesional pero tranquilizador
OBJETIVO: Informar sin alarmar, pero motivar acción

Incluye:
- Hallazgos importantes de manera objetiva
- Recomendaciones claras y accionables
- Apoyo disponible para seguimiento
- Mensaje de que la situación es manejable

EVITA:
- Lenguaje alarmista
- Palabras como "URGENTE", "CRÍTICO", "INMEDIATO"
- Tono de emergencia

USA:
- "Recomendamos atención prioritaria"
- "Es importante abordar estos hallazgos"
- "Estamos disponibles para apoyar"
```

#### 4. Re-desplegar

```bash
cd cdk
cdk deploy AIEmailStack
```

#### 5. Enviar Email con Nuevo Tono

```bash
aws lambda invoke \
  --function-name send-email \
  --payload '{"informe_id": 1}' \
  response.json
```

Revisa el nuevo email. Compara con el anterior.

### Comparación

| Aspecto | Tono Urgente | Tono Profesional |
|---------|--------------|------------------|
| Asunto | [URGENTE] Hallazgos críticos | Informe médico - Atención requerida |
| Apertura | "Requiere atención INMEDIATA" | "Le informamos sobre hallazgos importantes" |
| Cuerpo | Palabras en MAYÚSCULAS | Lenguaje objetivo y claro |
| Cierre | "Contactar HOY" | "Disponibles para consultas" |
| Impacto | Puede alarmar | Informa sin alarmar |

### Experimento Adicional: Tono Muy Formal

Prueba con un tono extremadamente formal:

```
Genera un email FORMAL CORPORATIVO para el contratista.

TONO: Extremadamente formal y técnico
OBJETIVO: Comunicación oficial

ESTILO:
- Lenguaje técnico médico
- Estructura de carta formal
- Referencias a normativas
- Terminología legal

Ejemplo de apertura:
"Estimado/a [Nombre],

Por medio de la presente, nos dirigimos a usted en cumplimiento
de la normativa vigente en materia de salud ocupacional..."
```

### Preguntas para Reflexionar

1. ¿Cómo afecta el tono a la percepción del mensaje?
2. ¿Qué tono es más apropiado para cada nivel de riesgo?
3. ¿Cómo balanceas urgencia con profesionalismo?

### Resultado Esperado

- **Tono Urgente**: Efectivo para acción inmediata, puede alarmar
- **Tono Profesional**: Balance entre seriedad y tranquilidad
- **Tono Formal**: Apropiado para comunicaciones oficiales

### Conclusión

El tono debe adaptarse a:
- **Nivel de riesgo**: ALTO = más urgente, BAJO = tranquilizador
- **Audiencia**: Gerentes = ejecutivo, Médicos = técnico
- **Contexto**: Primera notificación = informativo, Seguimiento = urgente

---

## 📚 Ejercicio 5: Comparar Resultados Con y Sin RAG

### Objetivo
Demostrar cómo RAG (contexto histórico) mejora la precisión y relevancia de las respuestas.

### Contexto
RAG proporciona contexto específico del trabajador, permitiendo clasificaciones y resúmenes más precisos que consideran tendencias.

### Pasos

#### 1. Crear Historial para un Trabajador

```bash
# Generar 3 informes para el mismo trabajador
for i in {1..3}; do
  aws lambda invoke \
    --function-name generate-test-data \
    --payload '{"trabajador_id": 1}' \
    response.json
  
  sleep 2
done

# Generar embeddings
for i in {1..3}; do
  aws lambda invoke \
    --function-name generate-embeddings \
    --payload "{\"informe_id\": $i}" \
    response.json
done
```

#### 2. Clasificar CON RAG (Configuración Actual)

```bash
aws lambda invoke \
  --function-name classify-risk \
  --payload '{"informe_id": 3}' \
  response_with_rag.json

cat response_with_rag.json
```

Anota la justificación. Debería mencionar tendencias o informes anteriores.

#### 3. Modificar Código para Omitir RAG

Edita `lambda/ai/classify_risk/index.py`:

```python
# Comentar la sección de RAG
# informes_anteriores = buscar_informes_similares(...)
# contexto_historico = construir_contexto(informes_anteriores)

# Usar contexto vacío
contexto_historico = "No hay informes anteriores disponibles."
```

#### 4. Re-desplegar

```bash
cd cdk
cdk deploy AIClassificationStack
```

#### 5. Clasificar SIN RAG

```bash
aws lambda invoke \
  --function-name classify-risk \
  --payload '{"informe_id": 3}' \
  response_without_rag.json

cat response_without_rag.json
```

### Comparación

| Aspecto | Sin RAG | Con RAG |
|---------|---------|---------|
| Contexto | Solo informe actual | Informe + historial |
| Justificación | Basada en valores absolutos | Basada en tendencias |
| Precisión | ~70% | ~85-90% |
| Ejemplo | "Presión 135/85 es MEDIO" | "Presión subió de 120/75 a 135/85, tendencia preocupante = MEDIO" |

### Ejemplo de Salida

**Sin RAG:**
```json
{
  "nivel_riesgo": "MEDIO",
  "justificacion": "Presión arterial en 135/85 mmHg está en rango de pre-hipertensión. IMC de 27.2 indica sobrepeso leve."
}
```

**Con RAG:**
```json
{
  "nivel_riesgo": "MEDIO",
  "justificacion": "Presión arterial ha aumentado progresivamente en los últimos 3 exámenes (120/75 → 128/80 → 135/85 mmHg), mostrando tendencia ascendente preocupante. IMC también aumentó de 25.1 a 27.2. Se recomienda seguimiento cercano para prevenir progresión a hipertensión."
}
```

### Preguntas para Reflexionar

1. ¿La justificación con RAG es más completa?
2. ¿RAG detecta tendencias que sin RAG no se ven?
3. ¿En qué casos es crítico tener contexto histórico?

### Resultado Esperado

- **Sin RAG**: Clasificación basada solo en valores actuales
- **Con RAG**: Clasificación considerando evolución y tendencias
- **Mejora**: 15-20% más de precisión con RAG

### Conclusión

RAG es esencial cuando:
- El contexto histórico es relevante
- Las tendencias importan más que valores absolutos
- Se necesita personalización por individuo

---


## 🎯 Resumen de Ejercicios

### Ejercicio 1: Temperature en Extracción
**Aprendizaje clave:** Temperature baja (0.1-0.2) para tareas que requieren consistencia.

### Ejercicio 2: maxTokens en Resúmenes
**Aprendizaje clave:** Ajustar maxTokens según longitud deseada, con margen de seguridad.

### Ejercicio 3: Few-Shot Learning
**Aprendizaje clave:** 2-3 ejemplos por categoría es óptimo para clasificación.

### Ejercicio 4: Control de Tono
**Aprendizaje clave:** El prompt controla el tono; adaptar según audiencia y urgencia.

### Ejercicio 5: RAG vs Sin RAG
**Aprendizaje clave:** RAG mejora significativamente cuando el contexto histórico es relevante.

---

## 📊 Tabla de Referencia Rápida

### Parámetros Recomendados por Tarea

| Tarea | Temperature | maxTokens | Few-Shot | RAG |
|-------|-------------|-----------|----------|-----|
| Extracción de datos | 0.1 - 0.2 | 1000-2000 | No necesario | No |
| Clasificación | 0.2 - 0.4 | 300-500 | Sí (2-3 ejemplos) | Sí |
| Resúmenes | 0.4 - 0.6 | 300-500 | Opcional | Sí |
| Emails | 0.6 - 0.8 | 500-800 | Opcional | Opcional |
| Contenido creativo | 0.7 - 0.9 | 800-1500 | Opcional | No |

### Guía de Temperature

| Rango | Uso | Características |
|-------|-----|-----------------|
| 0.0 - 0.2 | Extracción, datos | Determinístico, preciso, consistente |
| 0.3 - 0.5 | Análisis, clasificación | Balanceado, confiable |
| 0.6 - 0.8 | Contenido, emails | Creativo pero controlado |
| 0.9 - 1.0 | Brainstorming, ideas | Muy creativo, variado |

### Guía de maxTokens

| Longitud Deseada | maxTokens | Uso |
|------------------|-----------|-----|
| Muy corto (50 palabras) | 100-150 | Títulos, resúmenes ultra-cortos |
| Corto (100-150 palabras) | 200-300 | Resúmenes ejecutivos |
| Medio (200-300 palabras) | 400-600 | Análisis, emails |
| Largo (500+ palabras) | 1000-2000 | Informes detallados |

---

## 🔬 Experimentos Avanzados (Opcional)

### Experimento A: Combinar Múltiples Técnicas

Prueba combinar:
- Few-shot learning (3 ejemplos)
- RAG (contexto histórico)
- Temperature óptima (0.3)
- Prompt bien estructurado

Compara con configuración básica.

### Experimento B: Prompt Engineering Iterativo

1. Escribe un prompt básico
2. Prueba con 5 casos
3. Identifica errores comunes
4. Mejora el prompt
5. Repite hasta lograr 95%+ precisión

### Experimento C: A/B Testing de Prompts

Crea 2 versiones de un prompt:
- Versión A: Instrucciones directas
- Versión B: Con ejemplos y restricciones

Prueba con 20 casos y compara resultados.

### Experimento D: Optimización de Costos

Reduce costos sin sacrificar calidad:
1. Usa el modelo más pequeño que funcione
2. Reduce maxTokens al mínimo necesario
3. Optimiza prompts para ser más concisos
4. Implementa caching de respuestas comunes

---

## 📝 Plantilla de Documentación de Experimentos

Usa esta plantilla para documentar tus propios experimentos:

```markdown
## Experimento: [Nombre]

### Hipótesis
[Qué esperas que pase]

### Configuración
- Parámetro modificado: [nombre]
- Valor original: [valor]
- Valor nuevo: [valor]

### Metodología
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

### Resultados
| Métrica | Original | Nuevo | Diferencia |
|---------|----------|-------|------------|
| [Métrica 1] | [valor] | [valor] | [%] |
| [Métrica 2] | [valor] | [valor] | [%] |

### Observaciones
- [Observación 1]
- [Observación 2]

### Conclusión
[Qué aprendiste]

### Recomendación
[Qué configuración usar en producción]
```

---

## 🎓 Evaluación de Aprendizaje

Después de completar los ejercicios, deberías poder responder:

### Preguntas Conceptuales

1. ¿Cuándo usar temperature alta vs baja?
2. ¿Qué es few-shot learning y cuándo usarlo?
3. ¿Cómo RAG mejora las respuestas?
4. ¿Cómo controlar el tono del contenido generado?
5. ¿Qué es maxTokens y cómo afecta las respuestas?

### Preguntas Prácticas

1. ¿Qué temperature usarías para extraer datos de facturas?
2. ¿Cuántos ejemplos incluirías para clasificar sentimientos?
3. ¿Usarías RAG para generar descripciones de productos?
4. ¿Qué maxTokens configurarías para tweets (280 caracteres)?
5. ¿Cómo modificarías un prompt para hacerlo más formal?

### Desafío Final

Crea un nuevo caso de uso (ej: clasificar urgencia de tickets de soporte) y:
1. Diseña el prompt
2. Elige parámetros apropiados
3. Decide si usar RAG
4. Implementa y prueba
5. Itera hasta lograr 90%+ precisión

---

## 📚 Recursos Adicionales

### Documentación

- [Amazon Bedrock - Inference Parameters](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters.html)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [RAG Best Practices](https://aws.amazon.com/blogs/machine-learning/rag-best-practices/)

### Papers

- [Few-Shot Learning](https://arxiv.org/abs/2005.14165)
- [RAG: Retrieval-Augmented Generation](https://arxiv.org/abs/2005.11401)
- [Temperature in Language Models](https://arxiv.org/abs/1904.09751)

### Comunidades

- [AWS re:Post - Bedrock](https://repost.aws/tags/TA4IHBWMFxRRKzKzuCJAV_Aw/amazon-bedrock)
- [Prompt Engineering Discord](https://discord.gg/promptengineering)

---

## ✅ Checklist de Completitud

Marca los ejercicios que completaste:

- [ ] Ejercicio 1: Temperature en Extracción
- [ ] Ejercicio 2: maxTokens en Resúmenes
- [ ] Ejercicio 3: Few-Shot Learning en Clasificación
- [ ] Ejercicio 4: Modificar Tono en Emails
- [ ] Ejercicio 5: Comparar Con y Sin RAG

Experimentos opcionales:
- [ ] Experimento A: Combinar Múltiples Técnicas
- [ ] Experimento B: Prompt Engineering Iterativo
- [ ] Experimento C: A/B Testing de Prompts
- [ ] Experimento D: Optimización de Costos

---

## 🎉 ¡Felicitaciones!

Si completaste todos los ejercicios, ahora tienes experiencia práctica con:
- ✅ Ajuste de parámetros de modelos
- ✅ Prompt engineering efectivo
- ✅ Few-shot learning
- ✅ RAG (Retrieval-Augmented Generation)
- ✅ Control de tono y estilo
- ✅ Experimentación sistemática

Estás listo para aplicar estas técnicas en tus propios proyectos de IA Generativa.

---

**¿Preguntas?** Consulta con el instructor o revisa:
- [Guía para Participantes](../PARTICIPANT_GUIDE.md)
- [Guía del Instructor](../INSTRUCTOR_GUIDE.md)
- [README Principal](../README.md)
