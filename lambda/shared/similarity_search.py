"""
Módulo compartido para búsqueda por similitud usando pgvector.
Este módulo se empaqueta como Lambda Layer y se comparte entre múltiples Lambdas.
"""

import json
import os
import boto3

# Cliente RDS Data API
rds_data = boto3.client('rds-data')


def search_similar_informes(trabajador_id, query_embedding, limit=3, db_secret_arn=None, db_cluster_arn=None, database_name=None):
    """
    Busca informes similares usando búsqueda por similitud con pgvector.
    
    Args:
        trabajador_id: ID del trabajador para filtrar resultados
        query_embedding: Vector de embedding de la consulta (lista de floats)
        limit: Número máximo de resultados a retornar (default: 3)
        db_secret_arn: ARN del secreto de la base de datos (opcional, usa env var si no se provee)
        db_cluster_arn: ARN del cluster Aurora (opcional, usa env var si no se provee)
        database_name: Nombre de la base de datos (opcional, usa env var si no se provee)
    
    Returns:
        list: Lista de informes similares ordenados por similitud (más similar primero)
    """
    # Usar variables de entorno si no se proveen
    db_secret_arn = db_secret_arn or os.environ.get('DB_SECRET_ARN')
    db_cluster_arn = db_cluster_arn or os.environ.get('DB_CLUSTER_ARN')
    database_name = database_name or os.environ.get('DATABASE_NAME')
    
    if not all([db_secret_arn, db_cluster_arn, database_name]):
        raise ValueError("Database credentials not provided")
    
    # Convertir embedding a formato pgvector
    embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'
    
    # Query SQL con operador de distancia coseno de pgvector
    # El operador <=> calcula la distancia coseno (menor = más similar)
    sql = """
        SELECT 
            ie.informe_id,
            ie.trabajador_id,
            ie.contenido,
            ie.fecha_examen,
            im.tipo_examen,
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
            t.documento as trabajador_documento,
            (ie.embedding <=> :query_embedding::vector) as distance
        FROM informes_embeddings ie
        JOIN informes_medicos im ON ie.informe_id = im.id
        JOIN trabajadores t ON ie.trabajador_id = t.id
        WHERE ie.trabajador_id = :trabajador_id
        ORDER BY ie.embedding <=> :query_embedding::vector
        LIMIT :limit
    """
    
    params = [
        {'name': 'trabajador_id', 'value': {'longValue': int(trabajador_id)}},
        {'name': 'query_embedding', 'value': {'stringValue': embedding_str}},
        {'name': 'limit', 'value': {'longValue': int(limit)}}
    ]
    
    result = execute_sql(sql, params, db_secret_arn, db_cluster_arn, database_name)
    
    return parse_similarity_results(result)


def search_similar_informes_all_workers(query_embedding, current_informe_id=None, limit=5, db_secret_arn=None, db_cluster_arn=None, database_name=None):
    """
    Busca informes similares en toda la base de datos (sin filtrar por trabajador).
    Útil para análisis generales o comparaciones entre trabajadores.
    
    Args:
        query_embedding: Vector de embedding de la consulta (lista de floats)
        current_informe_id: ID del informe actual para excluirlo de resultados (opcional)
        limit: Número máximo de resultados a retornar (default: 5)
        db_secret_arn: ARN del secreto de la base de datos (opcional)
        db_cluster_arn: ARN del cluster Aurora (opcional)
        database_name: Nombre de la base de datos (opcional)
    
    Returns:
        list: Lista de informes similares ordenados por similitud
    """
    # Usar variables de entorno si no se proveen
    db_secret_arn = db_secret_arn or os.environ.get('DB_SECRET_ARN')
    db_cluster_arn = db_cluster_arn or os.environ.get('DB_CLUSTER_ARN')
    database_name = database_name or os.environ.get('DATABASE_NAME')
    
    if not all([db_secret_arn, db_cluster_arn, database_name]):
        raise ValueError("Database credentials not provided")
    
    # Convertir embedding a formato pgvector
    embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'
    
    # Query con estructura correcta: tabla separada informes_embeddings
    # Usa operador <=> para distancia coseno (0 = idéntico, 2 = opuesto)
    # Similitud = 1 - distancia
    if current_informe_id:
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
                t.documento as trabajador_documento,
                1 - (ie.embedding <=> :query_embedding::vector) as similarity
            FROM informes_medicos im
            JOIN informes_embeddings ie ON im.id = ie.informe_id
            JOIN trabajadores t ON im.trabajador_id = t.id
            WHERE im.id != :current_informe_id
            ORDER BY ie.embedding <=> :query_embedding::vector
            LIMIT :limit
        """
        params = [
            {'name': 'query_embedding', 'value': {'stringValue': embedding_str}},
            {'name': 'current_informe_id', 'value': {'longValue': int(current_informe_id)}},
            {'name': 'limit', 'value': {'longValue': int(limit)}}
        ]
    else:
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
                t.documento as trabajador_documento,
                1 - (ie.embedding <=> :query_embedding::vector) as similarity
            FROM informes_medicos im
            JOIN informes_embeddings ie ON im.id = ie.informe_id
            JOIN trabajadores t ON im.trabajador_id = t.id
            ORDER BY ie.embedding <=> :query_embedding::vector
            LIMIT :limit
        """
        params = [
            {'name': 'query_embedding', 'value': {'stringValue': embedding_str}},
            {'name': 'limit', 'value': {'longValue': int(limit)}}
        ]
    
    result = execute_sql(sql, params, db_secret_arn, db_cluster_arn, database_name)
    
    return parse_similarity_results_v2(result)


def get_historical_context(trabajador_id, current_informe_id=None, limit=3, db_secret_arn=None, db_cluster_arn=None, database_name=None):
    """
    Obtiene el contexto histórico de un trabajador (informes anteriores).
    Útil para clasificación de riesgo y generación de resúmenes.
    
    Args:
        trabajador_id: ID del trabajador
        current_informe_id: ID del informe actual (para excluirlo de los resultados)
        limit: Número máximo de informes históricos (default: 3)
        db_secret_arn: ARN del secreto de la base de datos (opcional)
        db_cluster_arn: ARN del cluster Aurora (opcional)
        database_name: Nombre de la base de datos (opcional)
    
    Returns:
        list: Lista de informes históricos ordenados por fecha (más reciente primero)
    """
    # Usar variables de entorno si no se proveen
    db_secret_arn = db_secret_arn or os.environ.get('DB_SECRET_ARN')
    db_cluster_arn = db_cluster_arn or os.environ.get('DB_CLUSTER_ARN')
    database_name = database_name or os.environ.get('DATABASE_NAME')
    
    if not all([db_secret_arn, db_cluster_arn, database_name]):
        raise ValueError("Database credentials not provided")
    
    # Query para obtener informes históricos
    if current_informe_id:
        sql = """
            SELECT 
                im.id as informe_id,
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
            WHERE im.trabajador_id = :trabajador_id
              AND im.id != :current_informe_id
            ORDER BY im.fecha_examen DESC
            LIMIT :limit
        """
        params = [
            {'name': 'trabajador_id', 'value': {'longValue': int(trabajador_id)}},
            {'name': 'current_informe_id', 'value': {'longValue': int(current_informe_id)}},
            {'name': 'limit', 'value': {'longValue': int(limit)}}
        ]
    else:
        sql = """
            SELECT 
                im.id as informe_id,
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
            WHERE im.trabajador_id = :trabajador_id
            ORDER BY im.fecha_examen DESC
            LIMIT :limit
        """
        params = [
            {'name': 'trabajador_id', 'value': {'longValue': int(trabajador_id)}},
            {'name': 'limit', 'value': {'longValue': int(limit)}}
        ]
    
    result = execute_sql(sql, params, db_secret_arn, db_cluster_arn, database_name)
    
    return parse_historical_results(result)


def cosine_similarity(vec1, vec2):
    """
    Calcula la similitud de coseno entre dos vectores.
    
    Args:
        vec1: Primer vector (lista de floats)
        vec2: Segundo vector (lista de floats)
    
    Returns:
        float: Similitud de coseno entre -1 y 1 (1 = idénticos, 0 = ortogonales, -1 = opuestos)
    """
    if len(vec1) != len(vec2):
        raise ValueError(f"Vectors must have same length: {len(vec1)} != {len(vec2)}")
    
    # Producto punto
    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    
    # Magnitudes
    magnitude1 = sum(a * a for a in vec1) ** 0.5
    magnitude2 = sum(b * b for b in vec2) ** 0.5
    
    # Evitar división por cero
    if magnitude1 == 0 or magnitude2 == 0:
        return 0.0
    
    # Similitud de coseno
    similarity = dot_product / (magnitude1 * magnitude2)
    
    return similarity


def parse_similarity_results(result):
    """
    Parsea los resultados de búsqueda por similitud (formato antiguo).
    
    Args:
        result: Resultado de execute_sql
    
    Returns:
        list: Lista de diccionarios con información de informes similares
    """
    informes = []
    
    for record in result.get('records', []):
        informe = {
            'informe_id': record[0].get('longValue'),
            'trabajador_id': record[1].get('longValue'),
            'contenido': record[2].get('stringValue', ''),
            'fecha_examen': record[3].get('stringValue', ''),
            'tipo_examen': record[4].get('stringValue', ''),
            'presion_arterial': record[5].get('stringValue', ''),
            'peso': record[6].get('doubleValue', 0),
            'altura': record[7].get('doubleValue', 0),
            'vision': record[8].get('stringValue', ''),
            'audiometria': record[9].get('stringValue', ''),
            'observaciones': record[10].get('stringValue', ''),
            'nivel_riesgo': record[11].get('stringValue') if not record[11].get('isNull') else None,
            'justificacion_riesgo': record[12].get('stringValue') if not record[12].get('isNull') else None,
            'resumen_ejecutivo': record[13].get('stringValue') if not record[13].get('isNull') else None,
            'trabajador_nombre': record[14].get('stringValue', ''),
            'trabajador_documento': record[15].get('stringValue', ''),
            'distance': record[16].get('doubleValue', 1.0),  # Distancia coseno (0 = idéntico, 1 = opuesto)
            'similarity': 1.0 - record[16].get('doubleValue', 1.0)  # Similitud (1 = idéntico, 0 = opuesto)
        }
        informes.append(informe)
    
    return informes


def parse_similarity_results_v2(result):
    """
    Parsea los resultados de búsqueda por similitud (formato actualizado con tabla separada).
    
    Args:
        result: Resultado de execute_sql
    
    Returns:
        list: Lista de diccionarios con información de informes similares
    """
    informes = []
    
    for record in result.get('records', []):
        informe = {
            'informe_id': record[0].get('longValue'),
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
            'trabajador_documento': record[14].get('stringValue', ''),
            'similarity_score': record[15].get('doubleValue', 0.0),  # Similitud (1 = idéntico, 0 = opuesto)
            'hallazgos_clave': record[9].get('stringValue', '')  # Usar observaciones como hallazgos
        }
        informes.append(informe)
    
    return informes


def parse_historical_results(result):
    """
    Parsea los resultados de consulta histórica.
    
    Args:
        result: Resultado de execute_sql
    
    Returns:
        list: Lista de diccionarios con información de informes históricos
    """
    informes = []
    
    for record in result.get('records', []):
        informe = {
            'informe_id': record[0].get('longValue'),
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
        informes.append(informe)
    
    return informes


def execute_sql(sql, parameters=None, db_secret_arn=None, db_cluster_arn=None, database_name=None):
    """
    Ejecuta una consulta SQL usando RDS Data API.
    
    Args:
        sql: Consulta SQL a ejecutar
        parameters: Parámetros de la consulta (opcional)
        db_secret_arn: ARN del secreto de la base de datos
        db_cluster_arn: ARN del cluster Aurora
        database_name: Nombre de la base de datos
    
    Returns:
        dict: Respuesta de RDS Data API
    """
    params = {
        'secretArn': db_secret_arn,
        'resourceArn': db_cluster_arn,
        'database': database_name,
        'sql': sql
    }
    
    if parameters:
        params['parameters'] = parameters
    
    response = rds_data.execute_statement(**params)
    return response


def format_context_for_prompt(informes):
    """
    Formatea una lista de informes para incluir en un prompt de IA.
    Útil para clasificación de riesgo y generación de resúmenes con contexto histórico.
    
    Args:
        informes: Lista de informes (de search_similar_informes o get_historical_context)
    
    Returns:
        str: Texto formateado para incluir en prompt
    """
    if not informes:
        return "No hay informes históricos disponibles."
    
    context_parts = []
    
    for i, informe in enumerate(informes, 1):
        parts = [f"\n--- Informe {i} (Fecha: {informe['fecha_examen']}) ---"]
        parts.append(f"Tipo: {informe['tipo_examen']}")
        
        if informe.get('presion_arterial'):
            parts.append(f"Presión arterial: {informe['presion_arterial']}")
        if informe.get('peso', 0) > 0:
            parts.append(f"Peso: {informe['peso']} kg")
        if informe.get('altura', 0) > 0:
            parts.append(f"Altura: {informe['altura']} m")
        if informe.get('vision'):
            parts.append(f"Visión: {informe['vision']}")
        if informe.get('audiometria'):
            parts.append(f"Audiometría: {informe['audiometria']}")
        if informe.get('observaciones'):
            parts.append(f"Observaciones: {informe['observaciones']}")
        if informe.get('nivel_riesgo'):
            parts.append(f"Nivel de riesgo: {informe['nivel_riesgo']}")
            if informe.get('justificacion_riesgo'):
                parts.append(f"Justificación: {informe['justificacion_riesgo']}")
        
        context_parts.append('\n'.join(parts))
    
    return '\n'.join(context_parts)
