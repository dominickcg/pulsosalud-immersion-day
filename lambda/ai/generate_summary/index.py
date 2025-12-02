"""
Lambda para generar resúmenes ejecutivos de informes médicos usando Bedrock Nova Pro.
Implementa RAG (Retrieval-Augmented Generation) con búsqueda SQL simple
para incluir contexto histórico en los resúmenes.
"""

import json
import boto3
import logging
import os
import time
from datetime import datetime

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clientes AWS
rds_data = boto3.client('rds-data')
bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-2')
s3_client = boto3.client('s3')

# Variables de entorno
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']
PROMPTS_BUCKET = os.environ['PROMPTS_BUCKET']

# Modelo de Bedrock
BEDROCK_MODEL_ID = 'us.amazon.nova-pro-v1:0'


# ========================================
# Excepciones personalizadas
# ========================================

class SummaryError(Exception):
    """Excepción base para errores de resumen"""
    http_status = 500


class InformeNotFoundError(SummaryError):
    """El informe no existe"""
    http_status = 404


class InformeNotClassifiedError(SummaryError):
    """El informe debe ser clasificado primero"""
    http_status = 400


class BedrockInvocationError(SummaryError):
    """Error al invocar Bedrock"""
    http_status = 502


class DatabaseError(SummaryError):
    """Error en operaciones de base de datos"""
    http_status = 500


# ========================================
# Funciones de Base de Datos
# ========================================

def execute_query(sql, parameters=None):
    """
    Ejecuta una query SQL usando RDS Data API.
    """
    try:
        params = {
            'resourceArn': DB_CLUSTER_ARN,
            'secretArn': DB_SECRET_ARN,
            'database': DATABASE_NAME,
            'sql': sql,
            'includeResultMetadata': True
        }
        
        if parameters:
            params['parameters'] = parameters
        
        response = rds_data.execute_statement(**params)
        return response
        
    except Exception as e:
        logger.error(f"Error ejecutando query: {str(e)}")
        raise DatabaseError(f"Error en base de datos: {str(e)}")


def format_records(response):
    """
    Formatea los registros de RDS Data API a diccionarios Python.
    """
    if 'records' not in response or not response['records']:
        return []
    
    columns = [col['name'] for col in response['columnMetadata']]
    
    formatted_records = []
    for record in response['records']:
        formatted_record = {}
        for i, col_name in enumerate(columns):
            value = record[i]
            
            if 'stringValue' in value:
                formatted_record[col_name] = value['stringValue']
            elif 'longValue' in value:
                formatted_record[col_name] = value['longValue']
            elif 'doubleValue' in value:
                formatted_record[col_name] = value['doubleValue']
            elif 'booleanValue' in value:
                formatted_record[col_name] = value['booleanValue']
            elif 'isNull' in value and value['isNull']:
                formatted_record[col_name] = None
            else:
                formatted_record[col_name] = None
        
        formatted_records.append(formatted_record)
    
    return formatted_records


def get_informe(informe_id):
    """
    Obtiene los datos completos de un informe médico.
    """
    logger.info(f"Obteniendo informe {informe_id}...")
    
    sql = """
    SELECT 
        i.id,
        i.trabajador_id,
        t.nombre as trabajador_nombre,
        t.documento as trabajador_documento,
        i.tipo_examen,
        i.fecha_examen,
        i.presion_arterial,
        i.peso,
        i.altura,
        i.vision,
        i.audiometria,
        i.observaciones,
        i.nivel_riesgo,
        i.justificacion_riesgo,
        c.nombre as contratista_nombre
    FROM informes_medicos i
    JOIN trabajadores t ON i.trabajador_id = t.id
    JOIN contratistas c ON i.contratista_id = c.id
    WHERE i.id = :informe_id;
    """
    
    parameters = [
        {'name': 'informe_id', 'value': {'longValue': informe_id}}
    ]
    
    response = execute_query(sql, parameters)
    informes = format_records(response)
    
    if not informes:
        raise InformeNotFoundError(f"Informe con ID {informe_id} no existe")
    
    informe = informes[0]
    
    # Verificar que el informe esté clasificado
    if not informe.get('nivel_riesgo'):
        raise InformeNotClassifiedError(
            f"El informe {informe_id} debe ser clasificado antes de generar el resumen"
        )
    
    # Calcular IMC si hay peso y altura
    if informe.get('peso') and informe.get('altura'):
        peso = float(informe['peso'])
        altura = float(informe['altura'])
        informe['imc'] = round(peso / (altura ** 2), 1)
    else:
        informe['imc'] = None
    
    logger.info(f"✓ Informe {informe_id} obtenido (Riesgo: {informe['nivel_riesgo']})")
    return informe


# ========================================
# RAG: Retrieval-Augmented Generation
# ========================================

def get_worker_history(trabajador_id, current_informe_id, limit=3):
    """
    RAG Step 1: RETRIEVE
    Busca informes anteriores del mismo trabajador usando SQL simple.
    
    Día 1 del workshop: Búsqueda SQL por trabajador_id
    Día 2 del workshop: Búsqueda vectorial con embeddings
    """
    logger.info(f"[RAG] Buscando historial del trabajador {trabajador_id}...")
    
    sql = """
    SELECT 
        fecha_examen,
        presion_arterial,
        peso,
        altura,
        nivel_riesgo,
        observaciones
    FROM informes_medicos
    WHERE trabajador_id = :trabajador_id
    AND id != :current_informe_id
    AND nivel_riesgo IS NOT NULL
    ORDER BY fecha_examen DESC
    LIMIT :limit;
    """
    
    parameters = [
        {'name': 'trabajador_id', 'value': {'longValue': trabajador_id}},
        {'name': 'current_informe_id', 'value': {'longValue': current_informe_id}},
        {'name': 'limit', 'value': {'longValue': limit}}
    ]
    
    response = execute_query(sql, parameters)
    history = format_records(response)
    
    logger.info(f"[RAG] ✓ {len(history)} informes anteriores encontrados")
    return history


def format_historical_context(history):
    """
    RAG Step 2: AUGMENT
    Formatea el historial para incluirlo en el prompt.
    """
    if not history:
        return "No hay informes anteriores de este trabajador."
    
    context = "HISTORIAL DEL TRABAJADOR:\n"
    
    for i, informe in enumerate(history, 1):
        fecha = informe.get('fecha_examen', 'Fecha desconocida')
        presion = informe.get('presion_arterial', 'N/A')
        peso = informe.get('peso', 'N/A')
        altura = informe.get('altura', 'N/A')
        riesgo = informe.get('nivel_riesgo', 'N/A')
        
        # Calcular IMC si hay datos
        imc = "N/A"
        if peso != 'N/A' and altura != 'N/A':
            try:
                imc = round(float(peso) / (float(altura) ** 2), 1)
            except:
                pass
        
        context += f"\n[Informe {i} - {fecha}]\n"
        context += f"- Presión arterial: {presion} mmHg\n"
        context += f"- Peso: {peso} kg, Altura: {altura} m, IMC: {imc}\n"
        context += f"- Nivel de riesgo: {riesgo}\n"
        
        if informe.get('observaciones'):
            obs = informe['observaciones'][:200]  # Limitar longitud
            context += f"- Observaciones: {obs}...\n"
    
    # Analizar tendencia
    if len(history) >= 2:
        try:
            # Comparar primer y último informe
            primer_riesgo = history[-1].get('nivel_riesgo')
            ultimo_riesgo = history[0].get('nivel_riesgo')
            
            if primer_riesgo and ultimo_riesgo:
                niveles = {'BAJO': 1, 'MEDIO': 2, 'ALTO': 3}
                if niveles.get(ultimo_riesgo, 0) > niveles.get(primer_riesgo, 0):
                    context += "\n⚠️ TENDENCIA: Deterioro progresivo en el tiempo\n"
                elif niveles.get(ultimo_riesgo, 0) < niveles.get(primer_riesgo, 0):
                    context += "\n✓ TENDENCIA: Mejora progresiva en el tiempo\n"
                else:
                    context += "\n→ TENDENCIA: Estable\n"
        except:
            pass
    
    return context


# ========================================
# Prompt Engineering
# ========================================

def load_prompt_template():
    """
    Carga el template de prompt desde S3.
    """
    logger.info(f"Cargando prompt template desde S3: {PROMPTS_BUCKET}/summary.txt")
    
    try:
        response = s3_client.get_object(
            Bucket=PROMPTS_BUCKET,
            Key='prompts/summary.txt'
        )
        
        template = response['Body'].read().decode('utf-8')
        logger.info("✓ Prompt template cargado")
        return template
        
    except Exception as e:
        logger.error(f"Error cargando prompt template: {str(e)}")
        raise DatabaseError(f"Error cargando prompt: {str(e)}")


def build_summary_prompt(informe, historical_context):
    """
    Construye el prompt completo para generación de resumen con RAG.
    """
    logger.info("Construyendo prompt de resumen...")
    
    # Cargar template
    template = load_prompt_template()
    
    # Formatear datos del informe actual
    datos_informe = f"""
Trabajador: {informe.get('trabajador_nombre', 'N/A')}
Documento: {informe.get('trabajador_documento', 'N/A')}
Tipo de examen: {informe.get('tipo_examen', 'N/A')}
Fecha: {informe.get('fecha_examen', 'N/A')}

PARÁMETROS CLÍNICOS:
- Presión arterial: {informe.get('presion_arterial', 'N/A')} mmHg
- Peso: {informe.get('peso', 'N/A')} kg
- Altura: {informe.get('altura', 'N/A')} m
- IMC: {informe.get('imc', 'N/A')}
- Visión: {informe.get('vision', 'N/A')}
- Audiometría: {informe.get('audiometria', 'N/A')}

OBSERVACIONES:
{informe.get('observaciones', 'Sin observaciones')}
"""
    
    # Reemplazar placeholders
    prompt = template.replace('{informes_anteriores}', historical_context)
    prompt = prompt.replace('{datos_informe}', datos_informe)
    prompt = prompt.replace('{nivel_riesgo}', informe.get('nivel_riesgo', 'N/A'))
    
    logger.info("✓ Prompt construido")
    return prompt


# ========================================
# Bedrock Invocation
# ========================================

def invoke_bedrock(prompt, temperature=0.5, max_tokens=300):
    """
    RAG Step 3: GENERATE
    Invoca Bedrock Nova Pro para generar el resumen.
    
    Temperature 0.5: Balance entre precisión y fluidez, ideal para resúmenes
    MaxTokens 300: Suficiente para 150 palabras (~200 tokens) con margen
    """
    logger.info(f"Invocando Bedrock {BEDROCK_MODEL_ID}...")
    logger.info(f"Parámetros: temperature={temperature}, maxTokens={max_tokens}")
    
    try:
        # Construir request body para Nova Pro
        request_body = {
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ],
            "inferenceConfig": {
                "temperature": temperature,
                "maxTokens": max_tokens
            }
        }
        
        start_time = time.time()
        
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        elapsed_time = time.time() - start_time
        
        # Parsear respuesta
        response_body = json.loads(response['body'].read())
        
        # Extraer texto de la respuesta
        if 'output' in response_body and 'message' in response_body['output']:
            content = response_body['output']['message']['content']
            if content and len(content) > 0:
                text_response = content[0]['text']
            else:
                raise BedrockInvocationError("Respuesta vacía de Bedrock")
        else:
            raise BedrockInvocationError("Formato de respuesta inesperado")
        
        logger.info(f"✓ Bedrock respondió en {elapsed_time:.2f}s")
        logger.info(f"Resumen generado: {text_response[:100]}...")
        
        return text_response, elapsed_time
        
    except Exception as e:
        logger.error(f"Error invocando Bedrock: {str(e)}")
        raise BedrockInvocationError(f"Error en Bedrock: {str(e)}")


def count_words(text):
    """
    Cuenta las palabras en el resumen.
    """
    # Limpiar el texto y contar palabras
    words = text.strip().split()
    return len(words)


# ========================================
# Guardar Resultado
# ========================================

def save_summary(informe_id, resumen):
    """
    Guarda el resumen ejecutivo en Aurora.
    """
    logger.info(f"Guardando resumen en Aurora...")
    
    sql = """
    UPDATE informes_medicos
    SET resumen_ejecutivo = :resumen
    WHERE id = :informe_id;
    """
    
    parameters = [
        {'name': 'resumen', 'value': {'stringValue': resumen}},
        {'name': 'informe_id', 'value': {'longValue': informe_id}}
    ]
    
    execute_query(sql, parameters)
    logger.info("✓ Resumen guardado en Aurora")


# ========================================
# Handler Principal
# ========================================

def generate_summary(informe_id, temperature=0.5, max_tokens=300):
    """
    Función principal que orquesta todo el proceso de generación de resumen con RAG.
    """
    start_time = time.time()
    
    logger.info(f"=== Iniciando generación de resumen para informe {informe_id} ===")
    
    # 1. Obtener informe actual (verifica que esté clasificado)
    informe = get_informe(informe_id)
    
    # 2. RAG: Recuperar historial del trabajador
    history = get_worker_history(
        informe['trabajador_id'],
        informe_id,
        limit=3
    )
    
    # 3. RAG: Formatear contexto histórico
    historical_context = format_historical_context(history)
    
    # 4. Construir prompt con contexto histórico
    prompt = build_summary_prompt(informe, historical_context)
    
    # 5. Invocar Bedrock Nova Pro
    resumen, bedrock_time = invoke_bedrock(prompt, temperature, max_tokens)
    
    # 6. Contar palabras
    word_count = count_words(resumen)
    logger.info(f"Resumen generado: {word_count} palabras")
    
    # 7. Guardar en Aurora
    save_summary(informe_id, resumen)
    
    total_time = time.time() - start_time
    
    logger.info(f"=== Resumen completado en {total_time:.2f}s ===")
    
    return {
        'informe_id': informe_id,
        'resumen': resumen,
        'palabras': word_count,
        'tiempo_procesamiento': f"{total_time:.2f}s",
        'incluye_contexto_historico': len(history) > 0
    }


def handler(event, context):
    """
    Handler de Lambda para API Gateway.
    """
    logger.info(f"Evento recibido: {json.dumps(event)}")
    
    try:
        # Parsear body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        # Extraer parámetros
        informe_id = body.get('informe_id')
        if not informe_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({
                    'error': 'BadRequest',
                    'message': 'Falta parámetro requerido: informe_id'
                })
            }
        
        temperature = body.get('temperature', 0.5)
        max_tokens = body.get('maxTokens', 300)
        
        # Generar resumen
        result = generate_summary(informe_id, temperature, max_tokens)
        
        # Retornar resultado
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps(result)
        }
        
    except InformeNotFoundError as e:
        logger.error(f"Informe no encontrado: {str(e)}")
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'InformeNotFoundError',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
    
    except InformeNotClassifiedError as e:
        logger.error(f"Informe no clasificado: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'InformeNotClassifiedError',
                'message': str(e),
                'hint': 'Clasifica el informe primero usando el endpoint /classify',
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except BedrockInvocationError as e:
        logger.error(f"Error de Bedrock: {str(e)}")
        return {
            'statusCode': 502,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'BedrockInvocationError',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except DatabaseError as e:
        logger.error(f"Error de base de datos: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'DatabaseError',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Error inesperado: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'InternalServerError',
                'message': 'Error interno del servidor',
                'details': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
