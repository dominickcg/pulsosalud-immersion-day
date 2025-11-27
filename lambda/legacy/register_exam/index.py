import json
import os
import boto3
from datetime import datetime

# Clientes AWS
secretsmanager = boto3.client('secretsmanager')
rds_data = boto3.client('rds-data')
lambda_client = boto3.client('lambda')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']
BUCKET_NAME = os.environ['BUCKET_NAME']


def handler(event, context):
    """
    Lambda para registrar exámenes médicos.
    Recibe datos del formulario, los valida, guarda en Aurora y genera PDF.
    """
    try:
        # Parsear el body del request
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Validar campos requeridos
        validation_error = validate_exam_data(body)
        if validation_error:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Validation error',
                    'message': validation_error
                })
            }
        
        # Extraer datos
        trabajador = body.get('trabajador', {})
        contratista = body.get('contratista', {})
        examen = body.get('examen', {})
        
        # Guardar en Aurora
        informe_id = save_to_aurora(trabajador, contratista, examen)
        
        # Invocar Lambda de generación de PDF
        pdf_result = invoke_pdf_generation(informe_id)
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'informe_id': informe_id,
                'pdf_url': pdf_result.get('pdf_url'),
                'message': 'Informe generado exitosamente'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }


def validate_exam_data(body):
    """Valida que los campos requeridos estén presentes."""
    if not body:
        return "Request body is required"
    
    trabajador = body.get('trabajador', {})
    if not trabajador.get('nombre'):
        return "trabajador.nombre is required"
    if not trabajador.get('documento'):
        return "trabajador.documento is required"
    
    contratista = body.get('contratista', {})
    if not contratista.get('nombre'):
        return "contratista.nombre is required"
    if not contratista.get('email'):
        return "contratista.email is required"
    
    examen = body.get('examen', {})
    if not examen.get('tipo'):
        return "examen.tipo is required"
    
    return None


def save_to_aurora(trabajador, contratista, examen):
    """Guarda los datos del examen en Aurora y retorna el ID del informe."""
    
    # 1. Insertar o obtener trabajador
    trabajador_id = upsert_trabajador(trabajador)
    
    # 2. Insertar o obtener contratista
    contratista_id = upsert_contratista(contratista)
    
    # 3. Insertar informe médico
    informe_id = insert_informe(trabajador_id, contratista_id, examen)
    
    return informe_id


def upsert_trabajador(trabajador):
    """Inserta o actualiza un trabajador y retorna su ID."""
    
    # Buscar si existe
    select_sql = """
        SELECT id FROM trabajadores 
        WHERE documento = :documento
    """
    
    result = execute_sql(select_sql, [
        {'name': 'documento', 'value': {'stringValue': trabajador['documento']}}
    ])
    
    if result['records']:
        return result['records'][0][0]['longValue']
    
    # Insertar nuevo trabajador
    insert_sql = """
        INSERT INTO trabajadores (nombre, documento, fecha_nacimiento)
        VALUES (:nombre, :documento, :fecha_nacimiento)
        RETURNING id
    """
    
    params = [
        {'name': 'nombre', 'value': {'stringValue': trabajador['nombre']}},
        {'name': 'documento', 'value': {'stringValue': trabajador['documento']}},
        {'name': 'fecha_nacimiento', 'value': {'stringValue': trabajador.get('fecha_nacimiento', '1990-01-01')}}
    ]
    
    result = execute_sql(insert_sql, params)
    return result['records'][0][0]['longValue']


def upsert_contratista(contratista):
    """Inserta o actualiza un contratista y retorna su ID."""
    
    # Buscar si existe
    select_sql = """
        SELECT id FROM contratistas 
        WHERE email = :email
    """
    
    result = execute_sql(select_sql, [
        {'name': 'email', 'value': {'stringValue': contratista['email']}}
    ])
    
    if result['records']:
        return result['records'][0][0]['longValue']
    
    # Insertar nuevo contratista
    insert_sql = """
        INSERT INTO contratistas (nombre, email)
        VALUES (:nombre, :email)
        RETURNING id
    """
    
    params = [
        {'name': 'nombre', 'value': {'stringValue': contratista['nombre']}},
        {'name': 'email', 'value': {'stringValue': contratista['email']}}
    ]
    
    result = execute_sql(insert_sql, params)
    return result['records'][0][0]['longValue']


def insert_informe(trabajador_id, contratista_id, examen):
    """Inserta un nuevo informe médico y retorna su ID."""
    
    insert_sql = """
        INSERT INTO informes_medicos (
            trabajador_id, contratista_id, tipo_examen, fecha_examen,
            presion_arterial, peso, altura, vision, audiometria, observaciones,
            origen
        )
        VALUES (
            :trabajador_id, :contratista_id, :tipo_examen, :fecha_examen,
            :presion_arterial, :peso, :altura, :vision, :audiometria, :observaciones,
            'LEGACY'
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
        {'name': 'observaciones', 'value': {'stringValue': examen.get('observaciones', '')}}
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


def invoke_pdf_generation(informe_id):
    """Invoca la Lambda de generación de PDF de forma asíncrona."""
    
    # Obtener el nombre de la función Lambda de generación de PDF
    # Asumimos que tiene el mismo prefijo que esta función
    function_name = os.environ.get('AWS_LAMBDA_FUNCTION_NAME', '')
    pdf_function_name = function_name.replace('register-exam', 'generate-pdf')
    
    payload = {
        'informe_id': informe_id
    }
    
    try:
        response = lambda_client.invoke(
            FunctionName=pdf_function_name,
            InvocationType='RequestResponse',  # Síncrono para obtener el resultado
            Payload=json.dumps(payload)
        )
        
        result = json.loads(response['Payload'].read())
        return result
        
    except Exception as e:
        print(f"Error invoking PDF generation: {str(e)}")
        return {'pdf_url': None, 'error': str(e)}
