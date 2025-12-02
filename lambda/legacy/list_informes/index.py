"""
Lambda para listar informes médicos.
Retorna un array con información básica de todos los informes para la app web.
"""

import json
import boto3
import logging
import os
from datetime import datetime

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Cliente RDS Data API
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']


def execute_query(sql, parameters=None):
    """
    Ejecuta una query SQL y retorna los resultados.
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
        raise


def format_records(response):
    """
    Formatea los registros de RDS Data API a formato JSON amigable.
    """
    if 'records' not in response or not response['records']:
        return []
    
    # Obtener nombres de columnas
    columns = [col['name'] for col in response['columnMetadata']]
    
    # Formatear cada registro
    formatted_records = []
    for record in response['records']:
        formatted_record = {}
        for i, col_name in enumerate(columns):
            value = record[i]
            
            # Extraer el valor según el tipo
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


def list_informes():
    """
    Lista todos los informes médicos con información básica.
    """
    logger.info("Listando informes médicos...")
    
    # Query con JOIN para obtener nombre del trabajador
    sql = """
    SELECT 
        i.id,
        t.nombre as trabajador_nombre,
        i.tipo_examen,
        i.presion_arterial,
        i.nivel_riesgo,
        i.fecha_examen
    FROM informes_medicos i
    JOIN trabajadores t ON i.trabajador_id = t.id
    ORDER BY i.fecha_examen DESC
    LIMIT 50;
    """
    
    response = execute_query(sql)
    informes = format_records(response)
    
    logger.info(f"✓ {len(informes)} informes encontrados")
    
    return informes


def handler(event, context):
    """
    Handler principal de la Lambda.
    """
    logger.info(f"Evento recibido: {json.dumps(event)}")
    
    try:
        # Listar informes
        informes = list_informes()
        
        # Retornar respuesta exitosa
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'informes': informes,
                'total': len(informes)
            }, default=str)  # default=str para manejar datetime
        }
        
    except Exception as e:
        logger.error(f"Error en handler: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'InternalServerError',
                'message': 'Error al listar informes',
                'details': str(e)
            })
        }
