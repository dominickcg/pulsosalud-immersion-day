# Notas de Iteración - Prompts de Clasificación de Riesgo

## Resumen
Este documento describe la evolución de los prompts de clasificación de riesgo médico, desde una versión básica hasta una versión optimizada con few-shot learning y contexto histórico (RAG).

---

## Versión 1: Prompt Básico

**Archivo:** `classification_v1.txt`

### Características
- Prompt minimalista
- Sin ejemplos
- Sin criterios detallados
- Sin contexto histórico

### Contenido
```
Clasifica el siguiente informe médico en uno de tres niveles de riesgo: BAJO, MEDIO o ALTO.

INFORME A CLASIFICAR:
{current}

Responde con un JSON:
{
  "nivel_riesgo": "BAJO|MEDIO|ALTO",
  "justificacion": "Explicación"
}
```

### Problemas Identificados
1. **Inconsistencia:** Sin criterios claros, el modelo puede clasificar de forma inconsistente
2. **Falta de contexto:** No considera el historial del trabajador
3. **Justificaciones vagas:** Sin guía, las explicaciones pueden ser genéricas
4. **Sin ejemplos:** El modelo no tiene referencias de qué constituye cada nivel

### Resultados Esperados
- Clasificaciones inconsistentes
- Justificaciones poco detalladas
- Dificultad para casos límite
- No considera tendencias históricas

---

## Versión 2: Prompt con Few-Shot Learning Básico

**Archivo:** `classification_v2.txt`

### Mejoras sobre V1
1. ✅ **Criterios claros:** Define qué constituye cada nivel de riesgo
2. ✅ **Ejemplos básicos:** Incluye un ejemplo de cada nivel
3. ✅ **Rol definido:** Especifica que es un médico ocupacional
4. ✅ **Formato estructurado:** Mejor organización del prompt

### Características Nuevas
- Definición de criterios para BAJO, MEDIO, ALTO
- Un ejemplo por cada nivel de riesgo
- Parámetros específicos en los ejemplos
- Instrucciones más claras

### Contenido Clave
```
CRITERIOS:
- BAJO: Parámetros normales, sin observaciones preocupantes
- MEDIO: Algunos parámetros fuera de rango, requiere seguimiento
- ALTO: Múltiples anomalías, requiere atención inmediata

EJEMPLOS:
Ejemplo BAJO: Presión: 120/80, IMC: 23.5, Visión: 20/20
Ejemplo MEDIO: Presión: 138/88, IMC: 28.7, Visión: 20/30
Ejemplo ALTO: Presión: 165/105, IMC: 32.9, Visión: 20/40
```

### Problemas Restantes
1. **Ejemplos simples:** Los ejemplos son muy breves, sin contexto completo
2. **Sin historial:** Aún no considera el contexto histórico del trabajador
3. **Justificaciones limitadas:** No guía sobre qué incluir en la justificación
4. **Sin análisis de tendencias:** No menciona la importancia de comparar con informes anteriores

### Resultados Esperados
- Clasificaciones más consistentes que V1
- Justificaciones más estructuradas
- Mejor manejo de casos típicos
- Aún limitado en casos complejos

---

## Versión 3: Prompt Optimizado con RAG y Few-Shot Detallado

**Archivo:** `classification_v3.txt`

### Mejoras sobre V2
1. ✅ **Ejemplos detallados:** Casos completos con todos los parámetros
2. ✅ **Contexto histórico (RAG):** Incluye informes anteriores del trabajador
3. ✅ **Análisis de tendencias:** Instruye al modelo a comparar con el historial
4. ✅ **Justificaciones guiadas:** Especifica qué debe incluir la justificación
5. ✅ **Casos realistas:** Ejemplos con historiales y tendencias

### Características Nuevas

#### 1. Ejemplos Completos
Cada ejemplo incluye:
- Datos completos del trabajador
- Todos los parámetros vitales
- Observaciones médicas
- Historial de exámenes anteriores
- Clasificación con justificación detallada

```
Ejemplo 2 - RIESGO MEDIO:
Trabajador: María González
Presión arterial: 138/88
Peso: 78 kg, Altura: 1.65 m, IMC: 28.7
Visión: 20/30 (reducida)
Audiometría: Leve pérdida en frecuencias altas
Observaciones: Sobrepeso. Se recomienda control de peso.
Historial: Hace 6 meses tenía presión 130/85 y peso 75 kg. Tendencia al alza.

Clasificación: MEDIO
Justificación: La presión arterial está en rango de pre-hipertensión (138/88) 
y ha aumentado respecto al historial. El IMC de 28.7 indica sobrepeso. 
La tendencia al alza en peso y presión es preocupante pero manejable con intervención.
```

#### 2. Integración RAG
```
CONTEXTO HISTÓRICO DEL TRABAJADOR (RAG):
{context}
```

El prompt ahora recibe el contexto histórico formateado, permitiendo:
- Comparación con informes anteriores
- Identificación de tendencias
- Clasificación más precisa basada en evolución

#### 3. Instrucciones Detalladas
```
INSTRUCCIONES:
1. Analiza cuidadosamente el informe actual
2. Compara con el historial del trabajador (si está disponible)
3. Identifica tendencias: ¿están mejorando, estables o empeorando?
4. Considera la combinación de factores, no solo valores individuales
5. Clasifica según los criterios establecidos
6. Proporciona una justificación que:
   - Mencione los parámetros clave
   - Compare con el historial
   - Explique por qué se asignó este nivel
   - Sea comprensible para personal no médico
```

#### 4. Criterios Expandidos
Cada nivel ahora incluye:
- Definición clara
- Características específicas
- Rangos de referencia (IMC, presión arterial)
- Ejemplos de parámetros

### Ventajas de V3

#### Consistencia
- Ejemplos detallados guían al modelo
- Criterios claros reducen ambigüedad
- Formato estructurado facilita parsing

#### Precisión
- Contexto histórico permite análisis de tendencias
- Ejemplos realistas cubren casos comunes
- Instrucciones detalladas mejoran razonamiento

#### Explicabilidad
- Justificaciones más completas
- Referencias al historial
- Lenguaje comprensible para no médicos

#### Adaptabilidad
- Funciona con o sin contexto histórico
- Maneja casos simples y complejos
- Escalable a diferentes tipos de exámenes

### Resultados Esperados
- Clasificaciones altamente consistentes
- Justificaciones detalladas y útiles
- Análisis de tendencias cuando hay historial
- Mejor manejo de casos límite
- Explicaciones comprensibles

---

## Comparación de Versiones

| Característica | V1 | V2 | V3 |
|----------------|----|----|-----|
| Criterios claros | ❌ | ✅ | ✅ |
| Ejemplos | ❌ | ✅ (básicos) | ✅ (detallados) |
| Contexto histórico (RAG) | ❌ | ❌ | ✅ |
| Análisis de tendencias | ❌ | ❌ | ✅ |
| Justificaciones guiadas | ❌ | ⚠️ (limitado) | ✅ |
| Casos realistas | ❌ | ⚠️ (simples) | ✅ |
| Instrucciones detalladas | ❌ | ⚠️ (básicas) | ✅ |
| Rangos de referencia | ❌ | ❌ | ✅ |

---

## Recomendaciones de Uso

### Para Desarrollo
- **Usar V1:** Solo para pruebas iniciales rápidas
- **Usar V2:** Para validar estructura básica
- **Usar V3:** Para producción y casos reales

### Para Experimentación
1. Comenzar con V1 para establecer baseline
2. Probar V2 para ver impacto de few-shot learning
3. Implementar V3 para máxima precisión

### Para Ajustes
Si V3 necesita ajustes:
- **Más ejemplos:** Agregar casos específicos de tu dominio
- **Criterios personalizados:** Ajustar rangos según tu población
- **Temperature:** Ajustar entre 0.1 (más determinístico) y 0.5 (más flexible)

---

## Métricas de Evaluación

### Consistencia
- Clasificar el mismo informe múltiples veces
- Verificar que el nivel de riesgo sea consistente
- V3 debería tener >95% de consistencia

### Precisión
- Comparar con clasificaciones de médicos expertos
- Medir acuerdo en casos claros (BAJO y ALTO)
- V3 debería tener >90% de acuerdo

### Explicabilidad
- Evaluar calidad de justificaciones
- Verificar que mencionen parámetros clave
- Verificar que comparen con historial cuando disponible

---

## Conclusión

La evolución de V1 a V3 demuestra la importancia de:
1. **Few-shot learning:** Los ejemplos guían significativamente al modelo
2. **Contexto histórico (RAG):** Permite análisis de tendencias
3. **Instrucciones claras:** Mejoran la calidad de las respuestas
4. **Criterios específicos:** Reducen ambigüedad y mejoran consistencia

**Versión recomendada para producción:** V3

**Próximos pasos:**
- Monitorear clasificaciones en producción
- Recopilar feedback de médicos
- Iterar en ejemplos según casos reales
- Ajustar criterios según necesidades específicas
