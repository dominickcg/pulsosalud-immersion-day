import json
import os
import boto3
from datetime import datetime
import urllib.parse

# Clientes AWS
s3_client = boto3.client('s3')
textract_client = boto3.client('textract')
bedrock_runtime = boto3.client('bedrock-runtime')
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']
BUCKET_NAME = os.environ['BUCKET_NAME']


def handler(event, context):
    """
    Lambda para extraer y procesar PDFs externos con IA.
    Usa Textract para extraer texto y Bedrock para estructurar datos.
    """
    try:
        print(f"Event received: {json.dumps(event)}")
        
        # Parsear evento de S3
        for record in event.get('Records', []):
            # Obtener información del archivo
            bucket = record['s3']['bucket']['name']
            key = urllib.parse.unquote_plus(record['s3']['object']['key'])
            
            print(f"Processing file: s3://{bucket}/{key}")
            
            # Verificar que es un PDF externo
            if not key.startswith('external-reports/'):
                print(f"Skipping file (not in external-reports/): {key}")
                continue
            
            # Extraer texto con Textract
            extracted_text = extract_text_from_pdf(bucket, key)
            
            if not extracted_text:
                print(f"No text extracted from {key}")
                continue
            
            # Estructurar datos con Bedrock
            structured_data = structure_data_with_bedrock(extracted_text)
            
            if not structured_data:
                print(f"Failed to structure data from {key}")
                continue
            
            # Guardar en Aurora
            informe_id = save_to_aurora(structured_data, f"s3://{bucket}/{key}")
            
            print(f"Successfully processed PDF. Informe ID: {informe_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'PDFs processed successfully'})
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


def extract_text_from_pdf(bucket, key):
    """
    Extrae texto de un PDF usando Amazon Textract.
    
    Args:
        bucket: Nombre del bucket S3
        key: Clave del objeto en S3
    
    Returns:
        str: Texto extraído del PDF
    """
    try:
        print(f"Extracting text with Textract from s3://{bucket}/{key}")
        
        # Llamar a Textract para detectar texto
        response = textract_client.detect_document_text(
            Document={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            }
        )
        
        # Extraer todo el texto de los bloques
        text_blocks = []
        for block in response.get('Blocks', []):
            if block['BlockType'] == 'LINE':
                text_blocks.append(block['Text'])
        
        extracted_text = '\n'.join(text_blocks)
        print(f"Extracted {len(extracted_text)} characters")
        
        return extracted_text
        
    except Exception as e:
        print(f"Error extracting text with Textract: {str(e)}")
        return None


def structure_data_with_bedrock(text):
    """
    Usa Amazon Bedrock (Nova Pro) para estructurar los datos extraídos.
    
    Args:
        text: Texto extraído del PDF
    
    Returns:
        dict: Datos estructurados en formato JSON
    """
    try:
        print("Structuring data with Bedrock (Amazon Nova Pro)")
        
        # Prompt para estructurar datos médicos
        prompt = f"""Extrae la siguiente información del informe médico y responde ÚNICAMENTE con un objeto JSON válido, sin texto adicional:

Texto del informe:
{text[:4000]}

Extrae:
- trabajador: {{nombre, documento}}
- contratista: {{nombre, email}}
- examen: {{tipo, presion_arterial, peso, altura, vision, audiometria, observaciones}}

Si algún campo no está presente, usa una cadena vacía o 0 para números.

Responde SOLO con el JSON, sin explicaciones:"""
        
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
                "temperature": 0.1,  # Bajo para extracción precisa
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
        
        # Intentar parsear el JSON
        # Limpiar el texto por si tiene markdown
        generated_text = generated_text.strip()
        if generated_text.startswith('```json'):
            generated_text = generated_text[7:]
        if generated_text.startswith('```'):
            generated_text = generated_text[3:]
        if generated_text.endswith('```'):
            generated_text = generated_text[:-3]
        generated_text = generated_text.strip()
        
        structured_data = json.loads(generated_text)
        
        print(f"Successfully structured data: {json.dumps(structured_data, indent=2)}")
        return structured_data
        
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON from Bedrock: {str(e)}")
        print(f"Generated text: {generated_text}")
        return None
    except Exception as e:
        print(f"Error structuring data with Bedrock: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def save_to_aurora(data, pdf_s3_path):
    """
    Guarda los datos estructurados en Aurora con el mismo formato que el sistema legacy.
    
    Args:
        data: Datos estructurados
        pdf_s3_path: Ruta del PDF en S3
    
    Returns:
        int: ID del informe creado
    """
    try:
        print("Saving structured data to Aurora")
        
        trabajador = data.get('trabajador', {})
        contratista = data.get('contratista', {})
        examen = data.get('examen', {})
        
        # 1. Upsert trabajador
        trabajador_id = upsert_trabajador(trabajador)
        
        # 2. Upsert contratista
        contratista_id = upsert_contratista(contratista)
        
        # 3. Insert informe
        informe_id = insert_informe(trabajador_id, contratista_id, examen, pdf_s3_path)
        
        print(f"Saved to Aurora. Informe ID: {informe_id}")
        return informe_id
        
    except Exception as e:
        print(f"Error saving to Aurora: {str(e)}")
        raise


def upsert_trabajador(trabajador):
    """Inserta o busca trabajador existente."""
    documento = trabajador.get('documento', '').strip()
    nombre = trabajador.get('nombre', '').strip()
    
    if not documento or not nombre:
        raise ValueError("Trabajador debe tener nombre y documento")
    
    # Buscar si existe
    select_sql = "SELECT id FROM trabajadores WHERE documento = :documento"
    result = execute_sql(select_sql, [
        {'name': 'documento', 'value': {'stringValue': documento}}
    ])
    
    if result['records']:
        return result['records'][0][0]['longValue']
    
    # Insertar nuevo
    insert_sql = """
        INSERT INTO trabajadores (nombre, documento, fecha_nacimiento)
        VALUES (:nombre, :documento, :fecha_nacimiento)
        RETURNING id
    """
    result = execute_sql(insert_sql, [
        {'name': 'nombre', 'value': {'stringValue': nombre}},
        {'name': 'documento', 'value': {'stringValue': documento}},
        {'name': 'fecha_nacimiento', 'value': {'stringValue': '1990-01-01'}}
    ])
    
    return result['records'][0][0]['longValue']


def upsert_contratista(contratista):
    """Inserta o busca contratista existente."""
    email = contratista.get('email', '').strip()
    nombre = contratista.get('nombre', '').strip()
    
    if not email or not nombre:
        raise ValueError("Contratista debe tener nombre y email")
    
    # Buscar si existe
    select_sql = "SELECT id FROM contratistas WHERE email = :email"
    result = execute_sql(select_sql, [
        {'name': 'email', 'value': {'stringValue': email}}
    ])
    
    if result['records']:
        return result['records'][0][0]['longValue']
    
    # Insertar nuevo
    insert_sql = """
        INSERT INTO contratistas (nombre, email)
        VALUES (:nombre, :email)
        RETURNING id
    """
    result = execute_sql(insert_sql, [
        {'name': 'nombre', 'value': {'stringValue': nombre}},
        {'name': 'email', 'value': {'stringValue': email}}
    ])
    
    return result['records'][0][0]['longValue']


def insert_informe(trabajador_id, contratista_id, examen, pdf_s3_path):
    """Inserta un nuevo informe médico."""
    insert_sql = """
        INSERT INTO informes_medicos (
            trabajador_id, contratista_id, tipo_examen, fecha_examen,
            presion_arterial, peso, altura, vision, audiometria, observaciones,
            pdf_s3_path, origen
        )
        VALUES (
            :trabajador_id, :contratista_id, :tipo_examen, :fecha_examen,
            :presion_arterial, :peso, :altura, :vision, :audiometria, :observaciones,
            :pdf_s3_path, 'EXTERNO'
        )
        RETURNING id
    """
    
    params = [
        {'name': 'trabajador_id', 'value': {'longValue': trabajador_id}},
        {'name': 'contratista_id', 'value': {'longValue': contratista_id}},
        {'name': 'tipo_examen', 'value': {'stringValue': examen.get('tipo', 'General')}},
        {'name': 'fecha_examen', 'value': {'stringValue': datetime.now().isoformat()}},
        {'name': 'presion_arterial', 'value': {'stringValue': examen.get('presion_arterial', '')}},
        {'name': 'peso', 'value': {'doubleValue': float(examen.get('peso', 0))}},
        {'name': 'altura', 'value': {'doubleValue': float(examen.get('altura', 0))}},
        {'name': 'vision', 'value': {'stringValue': examen.get('vision', '')}},
        {'name': 'audiometria', 'value': {'stringValue': examen.get('audiometria', '')}},
        {'name': 'observaciones', 'value': {'stringValue': examen.get('observaciones', '')}},
        {'name': 'pdf_s3_path', 'value': {'stringValue': pdf_s3_path}}
    ]
    
    result = execute_sql(insert_sql, params)
    return result['records'][0][0]['longValue']


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
