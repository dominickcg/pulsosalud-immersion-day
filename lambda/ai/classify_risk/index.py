import json
import os
import boto3
from datetime import datetime

# Importar funciones del Lambda Layer
from similarity_search import get_historical_context, format_context_for_prompt

# Clientes AWS
bedrock_runtime = boto3.client('bedrock-runtime')
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']


def handler(event, context):
    """
    Lambda para clasificar riesgo de informes médicos usando IA con contexto histórico (RAG).
    
    Puede ser invocada de dos formas:
    1. Sin parámetros: procesa todos los informes sin clasificar
    2. Con informe_id: procesa solo ese informe específico
    """
    try:
        print(f"Event received: {json.dumps(event)}")
        
        # Determinar qué informes procesar
        informe_id = event.get('informe_id')
        
        if informe_id:
            # Procesar un informe específico
            informes = get_informe_by_id(informe_id)
            print(f"Processing specific informe: {informe_id}")
        else:
            # Procesar todos los informes sin clasificar
            informes = get_informes_without_classification()
            print(f"Processing {len(informes)} informes without classification")
        
        if not informes:
            print("No informes to process")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No informes to process'})
            }
        
        # Procesar cada informe
        processed_count = 0
        for informe in informes:
            try:
                process_informe(informe)
                processed_count += 1
            except Exception as e:
                print(f"Error processing informe {informe['id']}: {str(e)}")
                continue
        
        print(f"Successfully processed {processed_count} informes")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully processed {processed_count} informes',
                'processed': processed_count,
                'total': len(informes)
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }


def get_informes_without_classification():
    """
    Obtiene todos los informes que no tienen clasificación de riesgo.
    
    Returns:
        list: Lista de informes sin clasificar
    """
    sql = """
        SELECT 
            im.id,
            im.trabajador_id,
            im.tipo_examen,
            im.fecha_examen,
            im.presion_arterial,
            im.peso,
            im.altura,
            im.vision,
            im.audiometria,
            im.observaciones,
            t.nombre as trabajador_nombre,
            t.documento as trabajador_documento,
            t.fecha_nacimiento as trabajador_fecha_nacimiento
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        WHERE im.nivel_riesgo IS NULL
        ORDER BY im.fecha_examen DESC
        LIMIT 50
    """
    
    result = execute_sql(sql)
    return parse_informes(result)


def get_informe_by_id(informe_id):
    """
    Obtiene un informe específico por su ID.
    
    Args:
        informe_id: ID del informe
    
    Returns:
        list: Lista con un solo informe
    """
    sql = """
        SELECT 
            im.id,
            im.trabajador_id,
            im.tipo_examen,
            im.fecha_examen,
            im.presion_arterial,
            im.peso,
            im.altura,
            im.vision,
            im.audiometria,
            im.observaciones,
            t.nombre as trabajador_nombre,
            t.documento as trabajador_documento,
            t.fecha_nacimiento as trabajador_fecha_nacimiento
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        WHERE im.id = :informe_id
    """
    
    result = execute_sql(sql, [
        {'name': 'informe_id', 'value': {'longValue': int(informe_id)}}
    ])
    
    return parse_informes(result)


def parse_informes(result):
    """
    Parsea los resultados de la consulta SQL a una lista de diccionarios.
    
    Args:
        result: Resultado de execute_sql
    
    Returns:
        list: Lista de informes como diccionarios
    """
    informes = []
    
    for record in result.get('records', []):
        informe = {
            'id': record[0].get('longValue'),
            'trabajador_id': record[1].get('longValue'),
            'tipo_examen': record[2].get('stringValue', ''),
            'fecha_examen': record[3].get('stringValue', ''),
            'presion_arterial': record[4].get('stringValue', ''),
            'peso': record[5].get('doubleValue', 0),
            'altura': record[6].get('doubleValue', 0),
            'vision': record[7].get('stringValue', ''),
            'audiometria': record[8].get('stringValue', ''),
            'observaciones': record[9].get('stringValue', ''),
            'trabajador_nombre': record[10].get('stringValue', ''),
            'trabajador_documento': record[11].get('stringValue', ''),
            'trabajador_fecha_nacimiento': record[12].get('stringValue', '')
        }
        informes.append(informe)
    
    return informes


def process_informe(informe):
    """
    Procesa un informe: obtiene contexto histórico y clasifica el riesgo.
    
    Args:
        informe: Diccionario con los datos del informe
    """
    informe_id = informe['id']
    trabajador_id = informe['trabajador_id']
    
    print(f"Processing informe {informe_id} for trabajador {trabajador_id}")
    
    # Obtener contexto histórico del trabajador (RAG)
    historical_context = get_historical_context(
        trabajador_id=trabajador_id,
        current_informe_id=informe_id,
        limit=3,
        db_secret_arn=DB_SECRET_ARN,
        db_cluster_arn=DB_CLUSTER_ARN,
        database_name=DATABASE_NAME
    )
    
    print(f"Found {len(historical_context)} historical informes")
    
    # Clasificar con Bedrock usando contexto histórico
    classification = classify_with_bedrock(informe, historical_context)
    
    if not classification:
        raise Exception(f"Failed to classify informe {informe_id}")
    
    # Actualizar Aurora con clasificación
    update_classification(informe_id, classification)
    
    print(f"Successfully classified informe {informe_id} as {classification['nivel_riesgo']}")


def classify_with_bedrock(informe, historical_context):
    """
    Clasifica el riesgo del informe usando Amazon Nova Pro con contexto histórico.
    
    Args:
        informe: Diccionario con los datos del informe actual
        historical_context: Lista de informes históricos del trabajador
    
    Returns:
        dict: {'nivel_riesgo': 'BAJO|MEDIO|ALTO', 'justificacion': 'texto'}
    """
    try:
        print("Classifying with Bedrock (Amazon Nova Pro)")
        
        # Formatear contexto histórico
        context_text = format_context_for_prompt(historical_context) if historical_context else "No hay informes históricos disponibles."
        
        # Crear texto del informe actual
        current_text = create_informe_text(informe)
        
        # Construir prompt con few-shot learning y contexto histórico
        prompt = build_classification_prompt(current_text, context_text)
        
        # Invocar Bedrock con Amazon Nova Pro
        request_body = {
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ],
            "inferenceConfig": {
                "max_new_tokens": 2000,
                "temperature": 0.3,  # Balance entre consistencia y flexibilidad
                "top_p": 0.9
            }
        }
        
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-pro-v1:0',
            body=json.dumps(request_body)
        )
        
        # Parsear respuesta
        response_body = json.loads(response['body'].read())
        
        # Extraer el texto de la respuesta
        content = response_body.get('output', {}).get('message', {}).get('content', [])
        if content and len(content) > 0:
            generated_text = content[0].get('text', '')
        else:
            print("No content in Bedrock response")
            return None
        
        print(f"Bedrock response: {generated_text[:500]}")
        
        # Parsear clasificación
        classification = parse_classification(generated_text)
        
        return classification
        
    except Exception as e:
        print(f"Error classifying with Bedrock: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def create_informe_text(informe):
    """
    Crea un texto representativo del informe para clasificación.
    
    Args:
        informe: Diccionario con los datos del informe
    
    Returns:
        str: Texto del informe
    """
    parts = []
    
    parts.append(f"Trabajador: {informe['trabajador_nombre']} ({informe['trabajador_documento']})")
    parts.append(f"Tipo de examen: {informe['tipo_examen']}")
    parts.append(f"Fecha: {informe['fecha_examen']}")
    
    if informe['presion_arterial']:
        parts.append(f"Presión arterial: {informe['presion_arterial']}")
    if informe['peso'] > 0:
        parts.append(f"Peso: {informe['peso']} kg")
    if informe['altura'] > 0:
        parts.append(f"Altura: {informe['altura']} m")
        if informe['peso'] > 0:
            imc = informe['peso'] / (informe['altura'] ** 2)
            parts.append(f"IMC: {imc:.1f}")
    if informe['vision']:
        parts.append(f"Visión: {informe['vision']}")
    if informe['audiometria']:
        parts.append(f"Audiometría: {informe['audiometria']}")
    if informe['observaciones']:
        parts.append(f"Observaciones: {informe['observaciones']}")
    
    return '\n'.join(parts)


def build_classification_prompt(current_text, context_text):
    """
    Construye el prompt de clasificación con few-shot learning y contexto histórico.
    
    Args:
        current_text: Texto del informe actual
        context_text: Texto del contexto histórico
    
    Returns:
        str: Prompt completo
    """
    prompt = """Eres un médico ocupacional experto. Tu tarea es clasificar informes médicos en tres niveles de riesgo: BAJO, MEDIO o ALTO.

CRITERIOS DE CLASIFICACIÓN:

RIESGO BAJO:
- Todos los parámetros dentro de rangos normales
- Sin observaciones preocupantes
- Historial estable o mejorando
- Ejemplo: Presión 120/80, peso normal, visión 20/20, sin observaciones

RIESGO MEDIO:
- Algunos parámetros fuera de rango normal
- Observaciones que requieren seguimiento
- Cambios moderados respecto al historial
- Ejemplo: Presión 140/90, sobrepeso leve, visión reducida, requiere seguimiento

RIESGO ALTO:
- Múltiples parámetros fuera de rango
- Observaciones críticas
- Deterioro significativo respecto al historial
- Requiere atención inmediata
- Ejemplo: Presión 160/100, obesidad, problemas auditivos severos, múltiples anomalías

CONTEXTO HISTÓRICO DEL TRABAJADOR:
{context}

INFORME ACTUAL A CLASIFICAR:
{current}

INSTRUCCIONES:
1. Analiza el informe actual
2. Compara con el historial del trabajador
3. Clasifica como BAJO, MEDIO o ALTO
4. Proporciona una justificación clara

Responde ÚNICAMENTE con un objeto JSON en este formato exacto:
{{
  "nivel_riesgo": "BAJO|MEDIO|ALTO",
  "justificacion": "Explicación clara de por qué se asignó este nivel de riesgo, considerando el historial"
}}

No incluyas texto adicional, solo el JSON."""

    return prompt.format(context=context_text, current=current_text)


def parse_classification(text):
    """
    Parsea la respuesta de Bedrock para extraer la clasificación.
    
    Args:
        text: Texto de respuesta de Bedrock
    
    Returns:
        dict: {'nivel_riesgo': str, 'justificacion': str}
    """
    try:
        # Limpiar el texto por si tiene markdown
        text = text.strip()
        if text.startswith('```json'):
            text = text[7:]
        if text.startswith('```'):
            text = text[3:]
        if text.endswith('```'):
            text = text[:-3]
        text = text.strip()
        
        # Parsear JSON
        classification = json.loads(text)
        
        # Validar nivel de riesgo
        nivel_riesgo = classification.get('nivel_riesgo', '').upper()
        if nivel_riesgo not in ['BAJO', 'MEDIO', 'ALTO']:
            print(f"Invalid risk level: {nivel_riesgo}, defaulting to MEDIO")
            nivel_riesgo = 'MEDIO'
        
        return {
            'nivel_riesgo': nivel_riesgo,
            'justificacion': classification.get('justificacion', '')
        }
        
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON from Bedrock: {str(e)}")
        print(f"Generated text: {text}")
        return None


def update_classification(informe_id, classification):
    """
    Actualiza el informe en Aurora con la clasificación de riesgo.
    
    Args:
        informe_id: ID del informe
        classification: Diccionario con nivel_riesgo y justificacion
    """
    sql = """
        UPDATE informes_medicos
        SET nivel_riesgo = :nivel_riesgo,
            justificacion_riesgo = :justificacion,
            procesado_por_ia = true,
            updated_at = :updated_at
        WHERE id = :informe_id
    """
    
    execute_sql(sql, [
        {'name': 'informe_id', 'value': {'longValue': informe_id}},
        {'name': 'nivel_riesgo', 'value': {'stringValue': classification['nivel_riesgo']}},
        {'name': 'justificacion', 'value': {'stringValue': classification['justificacion']}},
        {'name': 'updated_at', 'value': {'stringValue': datetime.now().isoformat()}}
    ])
    
    print(f"Updated informe {informe_id} with classification")


def execute_sql(sql, parameters=None):
    """Ejecuta una consulta SQL usando RDS Data API."""
    params = {
        'secretArn': DB_SECRET_ARN,
        'resourceArn': DB_CLUSTER_ARN,
        'database': DATABASE_NAME,
        'sql': sql
    }
    
    if parameters:
        params['parameters'] = parameters
    
    response = rds_data.execute_statement(**params)
    return response
