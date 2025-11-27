import json
import os
import boto3
from datetime import datetime
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
    Lambda para generar resúmenes ejecutivos de informes médicos usando IA con contexto histórico (RAG).
    Genera resúmenes de máximo 150 palabras en lenguaje claro y no técnico.
    """
    try:
        print(f"Event received: {json.dumps(event)}")
        
        informe_id = event.get('informe_id')
        
        if informe_id:
            informes = get_informe_by_id(informe_id)
        else:
            informes = get_informes_without_summary()
        
        if not informes:
            return {'statusCode': 200, 'body': json.dumps({'message': 'No informes to process'})}
        
        processed_count = 0
        for informe in informes:
            try:
                process_informe(informe)
                processed_count += 1
            except Exception as e:
                print(f"Error processing informe {informe['id']}: {str(e)}")
                continue
        
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
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}


def get_informes_without_summary():
    """Obtiene informes clasificados sin resumen."""
    sql = """
        SELECT im.id, im.trabajador_id, im.tipo_examen, im.fecha_examen,
               im.presion_arterial, im.peso, im.altura, im.vision, im.audiometria,
               im.observaciones, im.nivel_riesgo, im.justificacion_riesgo,
               t.nombre as trabajador_nombre
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        WHERE im.nivel_riesgo IS NOT NULL AND im.resumen_ejecutivo IS NULL
        ORDER BY im.fecha_examen DESC
        LIMIT 50
    """
    return parse_informes(execute_sql(sql))


def get_informe_by_id(informe_id):
    """Obtiene un informe específico."""
    sql = """
        SELECT im.id, im.trabajador_id, im.tipo_examen, im.fecha_examen,
               im.presion_arterial, im.peso, im.altura, im.vision, im.audiometria,
               im.observaciones, im.nivel_riesgo, im.justificacion_riesgo,
               t.nombre as trabajador_nombre
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        WHERE im.id = :informe_id
    """
    return parse_informes(execute_sql(sql, [{'name': 'informe_id', 'value': {'longValue': int(informe_id)}}]))


def parse_informes(result):
    """Parsea resultados SQL."""
    informes = []
    for record in result.get('records', []):
        informes.append({
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
            'nivel_riesgo': record[10].get('stringValue') if not record[10].get('isNull') else None,
            'justificacion_riesgo': record[11].get('stringValue') if not record[11].get('isNull') else None,
            'trabajador_nombre': record[12].get('stringValue', '')
        })
    return informes


def process_informe(informe):
    """Procesa un informe: obtiene contexto histórico y genera resumen."""
    informe_id = informe['id']
    trabajador_id = informe['trabajador_id']
    
    print(f"Processing informe {informe_id}")
    
    # Obtener contexto histórico (RAG)
    historical_context = get_historical_context(
        trabajador_id=trabajador_id,
        current_informe_id=informe_id,
        limit=5,
        db_secret_arn=DB_SECRET_ARN,
        db_cluster_arn=DB_CLUSTER_ARN,
        database_name=DATABASE_NAME
    )
    
    # Generar resumen con Bedrock
    summary = generate_summary_with_bedrock(informe, historical_context)
    
    if not summary:
        raise Exception(f"Failed to generate summary for informe {informe_id}")
    
    # Actualizar Aurora
    update_summary(informe_id, summary)
    print(f"Successfully generated summary for informe {informe_id}")


def generate_summary_with_bedrock(informe, historical_context):
    """Genera resumen ejecutivo usando Amazon Nova Pro."""
    try:
        context_text = format_context_for_prompt(historical_context) if historical_context else "No hay informes históricos."
        current_text = create_informe_text(informe)
        prompt = build_summary_prompt(current_text, context_text, informe.get('nivel_riesgo'))
        
        request_body = {
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {
                "max_new_tokens": 500,
                "temperature": 0.5,  # Más creativo que clasificación
                "top_p": 0.9
            }
        }
        
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-pro-v1:0',
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        content = response_body.get('output', {}).get('message', {}).get('content', [])
        
        if content and len(content) > 0:
            summary = content[0].get('text', '').strip()
            print(f"Generated summary: {summary[:100]}...")
            return summary
        
        return None
        
    except Exception as e:
        print(f"Error generating summary: {str(e)}")
        return None


def create_informe_text(informe):
    """Crea texto del informe."""
    parts = [
        f"Trabajador: {informe['trabajador_nombre']}",
        f"Tipo: {informe['tipo_examen']}",
        f"Fecha: {informe['fecha_examen']}"
    ]
    
    if informe['presion_arterial']:
        parts.append(f"Presión: {informe['presion_arterial']}")
    if informe['peso'] > 0:
        parts.append(f"Peso: {informe['peso']} kg")
    if informe['altura'] > 0:
        parts.append(f"Altura: {informe['altura']} m")
    if informe['vision']:
        parts.append(f"Visión: {informe['vision']}")
    if informe['audiometria']:
        parts.append(f"Audiometría: {informe['audiometria']}")
    if informe['observaciones']:
        parts.append(f"Observaciones: {informe['observaciones']}")
    if informe['nivel_riesgo']:
        parts.append(f"Nivel de riesgo: {informe['nivel_riesgo']}")
        if informe['justificacion_riesgo']:
            parts.append(f"Justificación: {informe['justificacion_riesgo']}")
    
    return '\n'.join(parts)


def build_summary_prompt(current_text, context_text, nivel_riesgo):
    """Construye prompt para generación de resumen."""
    prompt = f"""Eres un médico ocupacional experto. Genera un resumen ejecutivo del siguiente informe médico.

REQUISITOS:
- Máximo 150 palabras
- Lenguaje claro y no técnico (comprensible para gerentes de RRHH)
- Incluir análisis de tendencias si hay historial disponible
- Mencionar el nivel de riesgo y sus implicaciones
- Ser conciso pero informativo

CONTEXTO HISTÓRICO:
{context_text}

INFORME ACTUAL:
{current_text}

INSTRUCCIONES:
1. Resume los hallazgos principales del examen
2. Compara con el historial (si disponible) e identifica tendencias
3. Explica el nivel de riesgo ({nivel_riesgo}) en términos simples
4. Proporciona recomendaciones breves si es necesario
5. Usa lenguaje positivo y constructivo

Genera ÚNICAMENTE el resumen ejecutivo (máximo 150 palabras), sin encabezados ni formato adicional."""

    return prompt


def update_summary(informe_id, summary):
    """Actualiza el resumen en Aurora."""
    sql = """
        UPDATE informes_medicos
        SET resumen_ejecutivo = :summary,
            updated_at = :updated_at
        WHERE id = :informe_id
    """
    
    execute_sql(sql, [
        {'name': 'informe_id', 'value': {'longValue': informe_id}},
        {'name': 'summary', 'value': {'stringValue': summary}},
        {'name': 'updated_at', 'value': {'stringValue': datetime.now().isoformat()}}
    ])


def execute_sql(sql, parameters=None):
    """Ejecuta SQL usando RDS Data API."""
    params = {
        'secretArn': DB_SECRET_ARN,
        'resourceArn': DB_CLUSTER_ARN,
        'database': DATABASE_NAME,
        'sql': sql
    }
    if parameters:
        params['parameters'] = parameters
    return rds_data.execute_statement(**params)
