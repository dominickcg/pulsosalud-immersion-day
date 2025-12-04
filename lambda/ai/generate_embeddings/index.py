import json
import os
import boto3
from datetime import datetime

# Clientes AWS
bedrock_runtime = boto3.client('bedrock-runtime')
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']


def handler(event, context):
    """
    Lambda para generar embeddings de informes médicos usando Amazon Titan Embeddings.
    Lee informes de Aurora, genera embeddings y los guarda en la tabla informes_embeddings.
    
    Puede ser invocada de dos formas:
    1. Sin parámetros: procesa todos los informes sin embeddings
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
            # Procesar todos los informes sin embeddings
            informes = get_informes_without_embeddings()
            print(f"Processing {len(informes)} informes without embeddings")
        
        if not informes:
            print("No informes to process")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No informes to process'})
            }
        
        # Procesar cada informe
        processed_count = 0
        errors = []
        
        for informe in informes:
            try:
                process_informe(informe)
                processed_count += 1
                print(f"✓ Successfully processed informe {informe['id']}")
            except Exception as e:
                error_msg = f"Error processing informe {informe['id']}: {str(e)}"
                print(error_msg)
                import traceback
                traceback.print_exc()
                errors.append({
                    'informe_id': informe['id'],
                    'error': str(e)
                })
                continue
        
        print(f"Successfully processed {processed_count}/{len(informes)} informes")
        
        response_body = {
            'message': f'Successfully processed {processed_count} informes',
            'processed': processed_count,
            'total': len(informes),
            'details': [{
                'informe_id': inf['id'],
                'trabajador': inf.get('trabajador_nombre', 'N/A'),
                'tipo_examen': inf.get('tipo_examen', 'N/A'),
                'longitud_texto': len(create_text_for_embedding(inf))
            } for inf in informes if processed_count > 0]
        }
        
        if errors:
            response_body['errors'] = errors
            print(f"Errors encountered: {json.dumps(errors)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(response_body)
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


def get_informes_without_embeddings():
    """
    Obtiene todos los informes que no tienen embeddings generados.
    
    Returns:
        list: Lista de informes sin embeddings
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
            im.nivel_riesgo,
            im.justificacion_riesgo,
            im.resumen_ejecutivo,
            t.nombre as trabajador_nombre,
            t.documento as trabajador_documento
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        LEFT JOIN informes_embeddings ie ON im.id = ie.informe_id
        WHERE ie.id IS NULL
        ORDER BY im.fecha_examen DESC
        LIMIT 100
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
            im.nivel_riesgo,
            im.justificacion_riesgo,
            im.resumen_ejecutivo,
            t.nombre as trabajador_nombre,
            t.documento as trabajador_documento
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
    records = result.get('records', [])
    
    print(f"Parsing {len(records)} records from database")
    
    if not records:
        print("No records found in database result")
        return informes
    
    for idx, record in enumerate(records):
        try:
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
                'nivel_riesgo': record[10].get('stringValue') if not record[10].get('isNull') else None,
                'justificacion_riesgo': record[11].get('stringValue') if not record[11].get('isNull') else None,
                'resumen_ejecutivo': record[12].get('stringValue') if not record[12].get('isNull') else None,
                'trabajador_nombre': record[13].get('stringValue', ''),
                'trabajador_documento': record[14].get('stringValue', '')
            }
            
            # Validar que el informe tiene ID
            if not informe['id']:
                print(f"Warning: Record {idx} has no ID, skipping")
                continue
                
            informes.append(informe)
            print(f"✓ Parsed informe {informe['id']}: {informe['trabajador_nombre']}")
            
        except Exception as e:
            print(f"Error parsing record {idx}: {str(e)}")
            import traceback
            traceback.print_exc()
            continue
    
    print(f"Successfully parsed {len(informes)} informes")
    return informes


def process_informe(informe):
    """
    Procesa un informe: genera su embedding y lo guarda en la base de datos.
    
    Args:
        informe: Diccionario con los datos del informe
    """
    informe_id = informe['id']
    print(f"[STEP 1/3] Processing informe {informe_id}")
    
    # Crear texto para embedding
    print(f"[STEP 2/3] Creating text for embedding...")
    text_for_embedding = create_text_for_embedding(informe)
    print(f"[STEP 2/3] ✓ Text created: {len(text_for_embedding)} characters")
    
    # Generar embedding con Titan
    print(f"[STEP 3/3] Generating embedding with Bedrock Titan...")
    embedding = generate_embedding(text_for_embedding)
    
    if not embedding:
        raise Exception(f"Failed to generate embedding for informe {informe_id}")
    
    print(f"[STEP 3/3] ✓ Embedding generated: {len(embedding)} dimensions")
    
    # Guardar embedding en la base de datos
    print(f"[STEP 4/4] Saving embedding to database...")
    save_embedding(informe_id, embedding)
    print(f"[STEP 4/4] ✓ Embedding saved successfully")
    
    print(f"✓ Successfully processed informe {informe_id}")


def create_text_for_embedding(informe):
    """
    Crea un texto representativo del informe para generar el embedding.
    Incluye información clave del examen médico.
    
    Args:
        informe: Diccionario con los datos del informe
    
    Returns:
        str: Texto para generar embedding
    """
    parts = []
    
    # Información del trabajador
    parts.append(f"Trabajador: {informe['trabajador_nombre']} ({informe['trabajador_documento']})")
    
    # Tipo de examen y fecha
    parts.append(f"Tipo de examen: {informe['tipo_examen']}")
    parts.append(f"Fecha: {informe['fecha_examen']}")
    
    # Datos vitales
    if informe['presion_arterial']:
        parts.append(f"Presión arterial: {informe['presion_arterial']}")
    if informe['peso'] > 0:
        parts.append(f"Peso: {informe['peso']} kg")
    if informe['altura'] > 0:
        parts.append(f"Altura: {informe['altura']} m")
    
    # Evaluaciones
    if informe['vision']:
        parts.append(f"Visión: {informe['vision']}")
    if informe['audiometria']:
        parts.append(f"Audiometría: {informe['audiometria']}")
    
    # Observaciones
    if informe['observaciones']:
        parts.append(f"Observaciones: {informe['observaciones']}")
    
    # Nivel de riesgo (si existe)
    if informe['nivel_riesgo']:
        parts.append(f"Nivel de riesgo: {informe['nivel_riesgo']}")
        if informe['justificacion_riesgo']:
            parts.append(f"Justificación: {informe['justificacion_riesgo']}")
    
    # Resumen ejecutivo (si existe)
    if informe['resumen_ejecutivo']:
        parts.append(f"Resumen: {informe['resumen_ejecutivo']}")
    
    text = '\n'.join(parts)
    print(f"Created text for embedding ({len(text)} chars)")
    
    return text


def generate_embedding(text):
    """
    Genera un embedding vectorial usando Amazon Titan Embeddings v2.
    
    Args:
        text: Texto para generar embedding
    
    Returns:
        list: Vector de embedding (1024 dimensiones)
    """
    try:
        print(f"Generating embedding with Titan Embeddings v2 (text length: {len(text)} chars)")
        
        # Validar que el texto no esté vacío
        if not text or len(text.strip()) == 0:
            raise Exception("Cannot generate embedding for empty text")
        
        # Preparar request para Titan Embeddings v2
        request_body = {
            "inputText": text,
            "dimensions": 1024,  # Titan v2 soporta 256, 512, 1024
            "normalize": True    # Normalizar para cosine similarity
        }
        
        print(f"Invoking Bedrock model: amazon.titan-embed-text-v2:0")
        
        # Invocar Bedrock
        response = bedrock_runtime.invoke_model(
            modelId='amazon.titan-embed-text-v2:0',
            body=json.dumps(request_body)
        )
        
        print(f"✓ Bedrock response received")
        
        # Parsear respuesta
        response_body = json.loads(response['body'].read())
        embedding = response_body.get('embedding')
        
        if not embedding:
            print(f"ERROR: No embedding in response. Response body: {json.dumps(response_body)}")
            raise Exception("No embedding in Bedrock response")
        
        print(f"✓ Generated embedding with {len(embedding)} dimensions")
        return embedding
        
    except Exception as e:
        print(f"ERROR generating embedding: {str(e)}")
        import traceback
        traceback.print_exc()
        raise  # Re-raise para que el error se propague correctamente


def save_embedding(informe_id, embedding):
    """
    Guarda el embedding en la tabla informes_embeddings.
    
    Args:
        informe_id: ID del informe
        embedding: Vector de embedding
    """
    try:
        print(f"Converting embedding to pgvector format (vector length: {len(embedding)})")
        
        # Convertir embedding a formato pgvector (string)
        embedding_str = '[' + ','.join(map(str, embedding)) + ']'
        
        print(f"Embedding string length: {len(embedding_str)} chars")
        
        # Verificar si ya existe un embedding para este informe
        print(f"Checking if embedding already exists for informe {informe_id}")
        check_sql = "SELECT id FROM informes_embeddings WHERE informe_id = :informe_id"
        result = execute_sql(check_sql, [
            {'name': 'informe_id', 'value': {'longValue': informe_id}}
        ])
        
        if result.get('records'):
            # Actualizar embedding existente
            sql = """
                UPDATE informes_embeddings
                SET embedding = :embedding::vector,
                    fecha_generacion = CURRENT_TIMESTAMP
                WHERE informe_id = :informe_id
            """
            print(f"Updating existing embedding for informe {informe_id}")
        else:
            # Insertar nuevo embedding (fecha_generacion usa DEFAULT)
            sql = """
                INSERT INTO informes_embeddings (informe_id, embedding)
                VALUES (:informe_id, :embedding::vector)
            """
            print(f"Inserting new embedding for informe {informe_id}")
        
        print(f"Executing SQL to save embedding...")
        
        # Para RDS Data API, usar CURRENT_TIMESTAMP en lugar de pasar el valor
        # Esto evita problemas de conversión de tipos
        if result.get('records'):
            # UPDATE - no necesitamos fecha_generacion ya que se actualiza automáticamente
            execute_sql(sql, [
                {'name': 'informe_id', 'value': {'longValue': informe_id}},
                {'name': 'embedding', 'value': {'stringValue': embedding_str}}
            ])
        else:
            # INSERT - usar DEFAULT para fecha_generacion
            execute_sql(sql, [
                {'name': 'informe_id', 'value': {'longValue': informe_id}},
                {'name': 'embedding', 'value': {'stringValue': embedding_str}}
            ])
        
        print(f"✓ Successfully saved embedding for informe {informe_id}")
        
    except Exception as e:
        print(f"ERROR saving embedding for informe {informe_id}: {str(e)}")
        import traceback
        traceback.print_exc()
        raise


def execute_sql(sql, parameters=None):
    """Ejecuta una consulta SQL usando RDS Data API."""
    try:
        # Log de la query (truncar si es muy larga)
        sql_preview = sql[:200] + '...' if len(sql) > 200 else sql
        print(f"Executing SQL: {sql_preview}")
        
        if parameters:
            # Log de parámetros (sin mostrar el embedding completo)
            params_preview = []
            for p in parameters:
                if p['name'] == 'embedding':
                    params_preview.append(f"{p['name']}=[vector data, {len(p['value']['stringValue'])} chars]")
                else:
                    params_preview.append(f"{p['name']}={p['value']}")
            print(f"Parameters: {', '.join(params_preview)}")
        
        params = {
            'secretArn': DB_SECRET_ARN,
            'resourceArn': DB_CLUSTER_ARN,
            'database': DATABASE_NAME,
            'sql': sql
        }
        
        if parameters:
            params['parameters'] = parameters
        
        response = rds_data.execute_statement(**params)
        
        print(f"✓ SQL executed successfully")
        return response
        
    except Exception as e:
        print(f"ERROR executing SQL: {str(e)}")
        import traceback
        traceback.print_exc()
        raise
