import json
import os
import boto3
from datetime import datetime

# Clientes AWS
bedrock_runtime = boto3.client('bedrock-runtime')
ses_client = boto3.client('ses')
rds_data = boto3.client('rds-data')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']
VERIFIED_EMAIL = os.environ['VERIFIED_EMAIL']


def handler(event, context):
    """Lambda para enviar emails personalizados según nivel de riesgo."""
    try:
        informe_id = event.get('informe_id')
        informes = [get_informe_by_id(informe_id)] if informe_id else get_informes_pending_email()
        
        if not informes:
            return {'statusCode': 200, 'body': json.dumps({'message': 'No informes to process'})}
        
        processed = 0
        for informe in informes:
            try:
                process_informe(informe)
                processed += 1
            except Exception as e:
                print(f"Error processing informe {informe['id']}: {str(e)}")
        
        return {'statusCode': 200, 'body': json.dumps({'processed': processed, 'total': len(informes)})}
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}


def get_informes_pending_email():
    """Obtiene informes con resumen pero sin email enviado."""
    sql = """
        SELECT im.id, im.trabajador_id, im.nivel_riesgo, im.resumen_ejecutivo,
               t.nombre, c.email, c.nombre as contratista_nombre
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        JOIN contratistas c ON im.contratista_id = c.id
        WHERE im.resumen_ejecutivo IS NOT NULL AND im.email_enviado = false
        LIMIT 50
    """
    return parse_informes(execute_sql(sql))


def get_informe_by_id(informe_id):
    """Obtiene un informe específico."""
    sql = """
        SELECT im.id, im.trabajador_id, im.nivel_riesgo, im.resumen_ejecutivo,
               t.nombre, c.email, c.nombre as contratista_nombre
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        JOIN contratistas c ON im.contratista_id = c.id
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
            'nivel_riesgo': record[2].get('stringValue', ''),
            'resumen_ejecutivo': record[3].get('stringValue', ''),
            'trabajador_nombre': record[4].get('stringValue', ''),
            'contratista_email': record[5].get('stringValue', ''),
            'contratista_nombre': record[6].get('stringValue', '')
        })
    return informes


def process_informe(informe):
    """Procesa un informe: genera email y lo envía."""
    print(f"Processing informe {informe['id']}")
    
    # Generar email personalizado con Bedrock
    email_content = generate_email_with_bedrock(informe)
    
    if not email_content:
        raise Exception(f"Failed to generate email for informe {informe['id']}")
    
    # Enviar email con SES
    send_email_ses(informe, email_content)
    
    # Registrar envío en Aurora
    register_email_sent(informe['id'], informe['contratista_email'], email_content)
    
    print(f"Successfully sent email for informe {informe['id']}")


def generate_email_with_bedrock(informe):
    """Genera email personalizado usando Amazon Nova Pro."""
    try:
        nivel_riesgo = informe['nivel_riesgo']
        prompt = build_email_prompt(informe, nivel_riesgo)
        
        request_body = {
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {
                "max_new_tokens": 800,
                "temperature": 0.7,  # Más creativo para emails
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
            email_text = content[0].get('text', '').strip()
            print(f"Generated email: {email_text[:100]}...")
            return email_text
        
        return None
    except Exception as e:
        print(f"Error generating email: {str(e)}")
        return None


def build_email_prompt(informe, nivel_riesgo):
    """Construye prompt según nivel de riesgo."""
    base_prompt = f"""Genera un email profesional para notificar resultados de examen médico ocupacional.

INFORMACIÓN:
- Trabajador: {informe['trabajador_nombre']}
- Nivel de riesgo: {nivel_riesgo}
- Resumen: {informe['resumen_ejecutivo']}

"""
    
    if nivel_riesgo == 'ALTO':
        base_prompt += """TONO: Urgente pero profesional
REQUISITOS:
- Enfatizar la importancia de atención inmediata
- Mencionar acciones requeridas
- Mantener tono serio pero no alarmista
- Incluir contacto para seguimiento"""
    elif nivel_riesgo == 'MEDIO':
        base_prompt += """TONO: Profesional y constructivo
REQUISITOS:
- Indicar necesidad de seguimiento
- Proporcionar recomendaciones claras
- Mantener tono equilibrado
- Sugerir próximos pasos"""
    else:  # BAJO
        base_prompt += """TONO: Tranquilizador y positivo
REQUISITOS:
- Confirmar resultados satisfactorios
- Felicitar por buenos resultados
- Recordar importancia de mantener hábitos saludables
- Mencionar próximo examen de rutina"""
    
    base_prompt += "\n\nGenera ÚNICAMENTE el cuerpo del email (sin asunto), máximo 300 palabras."
    return base_prompt


def send_email_ses(informe, email_body):
    """Envía email usando Amazon SES."""
    subject = f"Resultados Examen Médico - {informe['trabajador_nombre']} - Riesgo {informe['nivel_riesgo']}"
    
    ses_client.send_email(
        Source=VERIFIED_EMAIL,
        Destination={'ToAddresses': [informe['contratista_email']]},
        Message={
            'Subject': {'Data': subject, 'Charset': 'UTF-8'},
            'Body': {'Text': {'Data': email_body, 'Charset': 'UTF-8'}}
        }
    )
    
    print(f"Email sent to {informe['contratista_email']}")


def register_email_sent(informe_id, email, content):
    """Registra envío de email en Aurora."""
    # Actualizar informe
    execute_sql("""
        UPDATE informes_medicos
        SET email_enviado = true, fecha_email_enviado = :fecha
        WHERE id = :informe_id
    """, [
        {'name': 'informe_id', 'value': {'longValue': informe_id}},
        {'name': 'fecha', 'value': {'stringValue': datetime.now().isoformat()}}
    ])
    
    # Registrar en historial
    execute_sql("""
        INSERT INTO historial_emails (informe_id, destinatario, cuerpo, estado, fecha_envio)
        VALUES (:informe_id, :email, :cuerpo, 'ENVIADO', :fecha)
    """, [
        {'name': 'informe_id', 'value': {'longValue': informe_id}},
        {'name': 'email', 'value': {'stringValue': email}},
        {'name': 'cuerpo', 'value': {'stringValue': content[:5000]}},
        {'name': 'fecha', 'value': {'stringValue': datetime.now().isoformat()}}
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
