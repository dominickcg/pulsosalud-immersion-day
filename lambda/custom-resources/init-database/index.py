"""
Custom Resource Lambda para inicializar la base de datos Aurora con datos de ejemplo.
Se ejecuta automáticamente cuando se despliega el LegacyStack.

Este script:
1. Crea la extensión pgvector (preparación para Día 2)
2. Crea las tablas necesarias
3. Inserta datos de ejemplo (trabajadores, contratistas, informes)
4. Es idempotente (puede ejecutarse múltiples veces sin duplicar datos)
"""

import json
import boto3
import logging
import os
from datetime import datetime

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clientes AWS
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']


def execute_sql(sql, parameters=None):
    """
    Ejecuta una query SQL usando RDS Data API.
    """
    try:
        params = {
            'resourceArn': DB_CLUSTER_ARN,
            'secretArn': DB_SECRET_ARN,
            'database': DATABASE_NAME,
            'sql': sql
        }
        
        if parameters:
            params['parameters'] = parameters
        
        response = rds_data.execute_statement(**params)
        logger.info(f"SQL ejecutado exitosamente: {sql[:100]}...")
        return response
    except Exception as e:
        logger.error(f"Error ejecutando SQL: {str(e)}")
        logger.error(f"SQL: {sql}")
        raise


def create_pgvector_extension():
    """
    Crea la extensión pgvector (preparación para Día 2).
    """
    logger.info("Creando extensión pgvector...")
    sql = "CREATE EXTENSION IF NOT EXISTS vector;"
    execute_sql(sql)
    logger.info("✓ Extensión pgvector creada")


def create_tables():
    """
    Crea las tablas necesarias si no existen.
    """
    logger.info("Creando tablas...")
    
    # Tabla: trabajadores
    sql_trabajadores = """
    CREATE TABLE IF NOT EXISTS trabajadores (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(200) NOT NULL,
        documento VARCHAR(50) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    execute_sql(sql_trabajadores)
    logger.info("✓ Tabla trabajadores creada")
    
    # Tabla: contratistas
    sql_contratistas = """
    CREATE TABLE IF NOT EXISTS contratistas (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(200) NOT NULL,
        email VARCHAR(200) NOT NULL UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    execute_sql(sql_contratistas)
    logger.info("✓ Tabla contratistas creada")
    
    # Tabla: informes_medicos
    sql_informes = """
    CREATE TABLE IF NOT EXISTS informes_medicos (
        id SERIAL PRIMARY KEY,
        trabajador_id INT NOT NULL,
        contratista_id INT NOT NULL,
        tipo_examen VARCHAR(100) NOT NULL,
        fecha_examen TIMESTAMP NOT NULL,
        presion_arterial VARCHAR(20),
        peso DECIMAL(5,2),
        altura DECIMAL(3,2),
        vision VARCHAR(200),
        audiometria VARCHAR(200),
        observaciones TEXT,
        nivel_riesgo VARCHAR(10),
        justificacion_riesgo TEXT,
        resumen_ejecutivo TEXT,
        pdf_s3_path VARCHAR(500),
        origen VARCHAR(20) DEFAULT 'LEGACY',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trabajador_id) REFERENCES trabajadores(id),
        FOREIGN KEY (contratista_id) REFERENCES contratistas(id)
    );
    """
    execute_sql(sql_informes)
    logger.info("✓ Tabla informes_medicos creada")
    
    # Crear índices
    indices = [
        "CREATE INDEX IF NOT EXISTS idx_trabajador ON informes_medicos(trabajador_id);",
        "CREATE INDEX IF NOT EXISTS idx_nivel_riesgo ON informes_medicos(nivel_riesgo);",
        "CREATE INDEX IF NOT EXISTS idx_fecha_examen ON informes_medicos(fecha_examen DESC);"
    ]
    
    for idx_sql in indices:
        execute_sql(idx_sql)
    
    logger.info("✓ Índices creados")


def insert_trabajadores():
    """
    Inserta trabajadores de ejemplo (idempotente).
    """
    logger.info("Insertando trabajadores de ejemplo...")
    
    trabajadores = [
        {"nombre": "Juan Pérez Gómez", "documento": "43567821"},
        {"nombre": "María González López", "documento": "41256789"},
        {"nombre": "Carlos Rodríguez Martínez", "documento": "09876543"},
        {"nombre": "Ana Torres Silva", "documento": "45123678"},
        {"nombre": "Luis Fernández Castro", "documento": "42987654"}
    ]
    
    for trabajador in trabajadores:
        sql = """
        INSERT INTO trabajadores (nombre, documento)
        VALUES (:nombre, :documento)
        ON CONFLICT (documento) DO NOTHING;
        """
        
        parameters = [
            {'name': 'nombre', 'value': {'stringValue': trabajador['nombre']}},
            {'name': 'documento', 'value': {'stringValue': trabajador['documento']}}
        ]
        
        execute_sql(sql, parameters)
    
    logger.info(f"✓ {len(trabajadores)} trabajadores insertados")


def insert_contratistas():
    """
    Inserta contratistas de ejemplo (idempotente).
    """
    logger.info("Insertando contratistas de ejemplo...")
    
    contratistas = [
        {"nombre": "Constructora Los Andes S.A.", "email": "contacto@constructoralosandes.com"},
        {"nombre": "Minera del Norte Ltda.", "email": "contacto@mineradelnorte.com"},
        {"nombre": "Transportes Rápidos del Sur S.A.", "email": "contacto@transportesrapidosdelsur.com"}
    ]
    
    for contratista in contratistas:
        sql = """
        INSERT INTO contratistas (nombre, email)
        VALUES (:nombre, :email)
        ON CONFLICT (email) DO NOTHING;
        """
        
        parameters = [
            {'name': 'nombre', 'value': {'stringValue': contratista['nombre']}},
            {'name': 'email', 'value': {'stringValue': contratista['email']}}
        ]
        
        execute_sql(sql, parameters)
    
    logger.info(f"✓ {len(contratistas)} contratistas insertados")


def insert_informes():
    """
    Inserta informes médicos de ejemplo con variedad de casos (idempotente).
    """
    logger.info("Insertando informes médicos de ejemplo...")
    
    # Verificar si ya existen informes
    check_sql = "SELECT COUNT(*) as count FROM informes_medicos;"
    result = execute_sql(check_sql)
    
    if result['records'] and result['records'][0][0]['longValue'] > 0:
        logger.info("✓ Informes ya existen, saltando inserción")
        return
    
    # Informes con variedad de casos: 3 BAJO, 4 MEDIO, 3 ALTO
    informes = [
        # BAJO riesgo (3 casos)
        {
            "trabajador_id": 1, "contratista_id": 1,
            "tipo_examen": "Pre-empleo", "fecha_examen": "2024-11-15 09:00:00",
            "presion_arterial": "118/75", "peso": 70.0, "altura": 1.75,
            "vision": "20/20", "audiometria": "Normal",
            "observaciones": "Paciente en excelente estado de salud. Todos los parámetros dentro de rangos normales."
        },
        {
            "trabajador_id": 2, "contratista_id": 1,
            "tipo_examen": "Periódico", "fecha_examen": "2024-11-20 10:30:00",
            "presion_arterial": "115/78", "peso": 65.0, "altura": 1.68,
            "vision": "20/20", "audiometria": "Normal",
            "observaciones": "Examen sin hallazgos patológicos. Paciente saludable."
        },
        {
            "trabajador_id": 3, "contratista_id": 2,
            "tipo_examen": "Pre-empleo", "fecha_examen": "2024-11-25 14:00:00",
            "presion_arterial": "122/80", "peso": 75.0, "altura": 1.80,
            "vision": "20/20", "audiometria": "Normal",
            "observaciones": "Paciente apto para el puesto. Sin restricciones."
        },
        
        # MEDIO riesgo (4 casos)
        {
            "trabajador_id": 4, "contratista_id": 2,
            "tipo_examen": "Periódico", "fecha_examen": "2024-11-28 11:00:00",
            "presion_arterial": "135/85", "peso": 85.0, "altura": 1.70,
            "vision": "20/25", "audiometria": "Normal",
            "observaciones": "Presión arterial en rango límite. Sobrepeso leve. Recomendar control periódico."
        },
        {
            "trabajador_id": 5, "contratista_id": 3,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-01 09:30:00",
            "presion_arterial": "138/88", "peso": 88.0, "altura": 1.75,
            "vision": "20/20", "audiometria": "Leve pérdida en frecuencias altas",
            "observaciones": "Pre-hipertensión. Sobrepeso. Recomendar cambios en estilo de vida."
        },
        {
            "trabajador_id": 1, "contratista_id": 1,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-05 15:00:00",
            "presion_arterial": "132/84", "peso": 78.0, "altura": 1.75,
            "vision": "20/20", "audiometria": "Normal",
            "observaciones": "Ligero aumento de presión desde último examen. Monitorear."
        },
        {
            "trabajador_id": 2, "contratista_id": 2,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-08 10:00:00",
            "presion_arterial": "140/90", "peso": 72.0, "altura": 1.68,
            "vision": "20/25", "audiometria": "Normal",
            "observaciones": "Hipertensión grado 1. Requiere seguimiento médico."
        },
        
        # ALTO riesgo (3 casos)
        {
            "trabajador_id": 3, "contratista_id": 3,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-10 11:30:00",
            "presion_arterial": "165/102", "peso": 95.0, "altura": 1.80,
            "vision": "20/30", "audiometria": "Pérdida moderada",
            "observaciones": "Hipertensión arterial severa. Obesidad. Requiere evaluación cardiológica urgente."
        },
        {
            "trabajador_id": 4, "contratista_id": 1,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-12 14:30:00",
            "presion_arterial": "158/98", "peso": 92.0, "altura": 1.70,
            "vision": "20/40", "audiometria": "Normal",
            "observaciones": "Hipertensión grado 2. Obesidad grado I. Antecedentes de diabetes. Riesgo cardiovascular alto."
        },
        {
            "trabajador_id": 5, "contratista_id": 2,
            "tipo_examen": "Periódico", "fecha_examen": "2024-12-15 16:00:00",
            "presion_arterial": "170/105", "peso": 98.0, "altura": 1.75,
            "vision": "20/30", "audiometria": "Pérdida leve",
            "observaciones": "Hipertensión severa. Obesidad grado II. Requiere atención médica inmediata y restricción de actividades de alto esfuerzo."
        }
    ]
    
    for informe in informes:
        sql = """
        INSERT INTO informes_medicos (
            trabajador_id, contratista_id, tipo_examen, fecha_examen,
            presion_arterial, peso, altura, vision, audiometria, observaciones
        ) VALUES (
            :trabajador_id, :contratista_id, :tipo_examen, :fecha_examen,
            :presion_arterial, :peso, :altura, :vision, :audiometria, :observaciones
        );
        """
        
        parameters = [
            {'name': 'trabajador_id', 'value': {'longValue': informe['trabajador_id']}},
            {'name': 'contratista_id', 'value': {'longValue': informe['contratista_id']}},
            {'name': 'tipo_examen', 'value': {'stringValue': informe['tipo_examen']}},
            {'name': 'fecha_examen', 'value': {'stringValue': informe['fecha_examen']}},
            {'name': 'presion_arterial', 'value': {'stringValue': informe['presion_arterial']}},
            {'name': 'peso', 'value': {'doubleValue': informe['peso']}},
            {'name': 'altura', 'value': {'doubleValue': informe['altura']}},
            {'name': 'vision', 'value': {'stringValue': informe['vision']}},
            {'name': 'audiometria', 'value': {'stringValue': informe['audiometria']}},
            {'name': 'observaciones', 'value': {'stringValue': informe['observaciones']}}
        ]
        
        execute_sql(sql, parameters)
    
    logger.info(f"✓ {len(informes)} informes médicos insertados (3 BAJO, 4 MEDIO, 3 ALTO)")


def initialize_database():
    """
    Inicializa la base de datos completa.
    """
    logger.info("=== Iniciando inicialización de base de datos ===")
    
    try:
        # 1. Crear extensión pgvector (preparación para Día 2)
        create_pgvector_extension()
        
        # 2. Crear tablas
        create_tables()
        
        # 3. Insertar datos de ejemplo
        insert_trabajadores()
        insert_contratistas()
        insert_informes()
        
        logger.info("=== Inicialización completada exitosamente ===")
        return {
            'statusCode': 200,
            'body': 'Base de datos inicializada correctamente'
        }
        
    except Exception as e:
        logger.error(f"Error en inicialización: {str(e)}")
        raise


def send_response(event, context, response_status, response_data):
    """
    Envía respuesta a CloudFormation.
    """
    import urllib3
    
    response_body = json.dumps({
        'Status': response_status,
        'Reason': f'See CloudWatch Log Stream: {context.log_stream_name}',
        'PhysicalResourceId': context.log_stream_name,
        'StackId': event['StackId'],
        'RequestId': event['RequestId'],
        'LogicalResourceId': event['LogicalResourceId'],
        'Data': response_data
    })
    
    headers = {
        'Content-Type': '',
        'Content-Length': str(len(response_body))
    }
    
    try:
        http = urllib3.PoolManager()
        response = http.request(
            'PUT',
            event['ResponseURL'],
            body=response_body,
            headers=headers
        )
        logger.info(f"CloudFormation response status: {response.status}")
    except Exception as e:
        logger.error(f"Error enviando respuesta a CloudFormation: {str(e)}")


def handler(event, context):
    """
    Handler principal del Custom Resource.
    """
    logger.info(f"Evento recibido: {json.dumps(event)}")
    
    request_type = event['RequestType']
    logger.info(f"Request Type: {request_type}")
    
    try:
        if request_type in ['Create', 'Update']:
            # Inicializar base de datos
            result = initialize_database()
            send_response(event, context, 'SUCCESS', result)
            
        elif request_type == 'Delete':
            # No hacer nada en Delete (las tablas se mantienen)
            logger.info("Delete request - no action needed")
            send_response(event, context, 'SUCCESS', {})
            
        else:
            logger.warning(f"Unknown request type: {request_type}")
            send_response(event, context, 'SUCCESS', {})
            
    except Exception as e:
        logger.error(f"Error en handler: {str(e)}")
        send_response(event, context, 'FAILED', {'Error': str(e)})
        raise
    
    return {'statusCode': 200}
