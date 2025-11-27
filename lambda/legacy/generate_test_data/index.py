import json
import os
import random
from datetime import datetime, timedelta

# Nota: Faker se instalará como layer o en el paquete de deployment
try:
    from faker import Faker
except ImportError:
    # Fallback si Faker no está disponible
    Faker = None

# Variables de entorno
DB_SECRET_ARN = os.environ.get('DB_SECRET_ARN')
DB_CLUSTER_ARN = os.environ.get('DB_CLUSTER_ARN')
DATABASE_NAME = os.environ.get('DATABASE_NAME')
BUCKET_NAME = os.environ.get('BUCKET_NAME')


def handler(event, context):
    """
    Lambda para generar datos de prueba realistas.
    Genera un informe médico completo con datos aleatorios pero realistas.
    """
    try:
        # Parsear el body del request
        if isinstance(event.get('body'), str):
            body = json.loads(event['body']) if event.get('body') else {}
        else:
            body = event.get('body', {})
        
        # Obtener nivel de riesgo deseado (opcional)
        nivel_riesgo_deseado = body.get('nivel_riesgo_deseado', random.choice(['BAJO', 'MEDIO', 'ALTO']))
        
        # Generar datos de prueba
        datos_prueba = generar_datos_prueba(nivel_riesgo_deseado)
        
        # Invocar la Lambda de registro de exámenes
        import boto3
        lambda_client = boto3.client('lambda')
        
        # Obtener el nombre de la función de registro
        function_name = os.environ.get('AWS_LAMBDA_FUNCTION_NAME', '')
        register_function_name = function_name.replace('generate-test-data', 'register-exam')
        
        # Invocar Lambda de registro
        response = lambda_client.invoke(
            FunctionName=register_function_name,
            InvocationType='RequestResponse',
            Payload=json.dumps({'body': json.dumps(datos_prueba)})
        )
        
        result = json.loads(response['Payload'].read())
        
        if result.get('statusCode') != 200:
            raise Exception(f"Error al registrar examen: {result}")
        
        result_body = json.loads(result['body'])
        informe_id = result_body.get('informe_id')
        pdf_url = result_body.get('pdf_url')
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'informe_id': informe_id,
                'pdf_url': pdf_url,
                'nivel_riesgo_generado': nivel_riesgo_deseado,
                'datos_generados': datos_prueba,
                'message': 'Datos de prueba generados exitosamente'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }


def generar_datos_prueba(nivel_riesgo='MEDIO'):
    """
    Genera datos de prueba realistas para un informe médico.
    
    Args:
        nivel_riesgo: 'BAJO', 'MEDIO', o 'ALTO'
    
    Returns:
        dict con trabajador, contratista y examen
    """
    
    # Inicializar Faker con locale español
    if Faker:
        fake = Faker('es_ES')
    else:
        fake = None
    
    # Generar datos del trabajador
    trabajador = generar_trabajador(fake)
    
    # Generar datos del contratista
    contratista = generar_contratista(fake)
    
    # Generar datos del examen según nivel de riesgo
    examen = generar_examen(nivel_riesgo, fake)
    
    return {
        'trabajador': trabajador,
        'contratista': contratista,
        'examen': examen
    }


def generar_trabajador(fake):
    """Genera datos realistas de un trabajador."""
    
    if fake:
        nombre = fake.name()
        documento = str(fake.random_number(digits=8, fix_len=True))
        fecha_nacimiento = fake.date_of_birth(minimum_age=18, maximum_age=65).isoformat()
    else:
        # Fallback sin Faker
        nombres = ['Juan Pérez', 'María García', 'Carlos López', 'Ana Martínez', 'Luis Rodríguez']
        nombre = random.choice(nombres)
        documento = str(random.randint(10000000, 99999999))
        edad = random.randint(18, 65)
        fecha_nacimiento = (datetime.now() - timedelta(days=edad*365)).date().isoformat()
    
    genero = random.choice(['Masculino', 'Femenino'])
    puesto = random.choice([
        'Operador de maquinaria',
        'Supervisor de obra',
        'Electricista',
        'Soldador',
        'Albañil',
        'Ingeniero de campo',
        'Técnico de mantenimiento'
    ])
    
    return {
        'nombre': nombre,
        'documento': documento,
        'fecha_nacimiento': fecha_nacimiento,
        'genero': genero,
        'puesto': puesto
    }


def generar_contratista(fake):
    """Genera datos realistas de un contratista."""
    
    if fake:
        nombre_empresa = fake.company()
        email = fake.company_email()
    else:
        # Fallback sin Faker
        empresas = ['Constructora ABC', 'Ingeniería XYZ', 'Obras Civiles SAC', 'Construcciones del Sur']
        nombre_empresa = random.choice(empresas)
        email = f"rrhh@{nombre_empresa.lower().replace(' ', '')}.com"
    
    return {
        'nombre': nombre_empresa,
        'email': email
    }


def generar_examen(nivel_riesgo, fake):
    """
    Genera datos de examen médico según el nivel de riesgo deseado.
    
    Args:
        nivel_riesgo: 'BAJO', 'MEDIO', o 'ALTO'
        fake: Instancia de Faker o None
    """
    
    tipo_examen = random.choice([
        'Pre-empleo',
        'Periódico',
        'Post-empleo',
        'Reintegro laboral'
    ])
    
    # Generar valores según nivel de riesgo
    if nivel_riesgo == 'ALTO':
        presion_sistolica = random.randint(150, 180)
        presion_diastolica = random.randint(95, 110)
        peso = round(random.uniform(95, 120), 1)
        altura = round(random.uniform(1.60, 1.85), 2)
        imc = peso / (altura ** 2)
        
        # Laboratorio con valores de riesgo
        colesterol_total = random.randint(240, 280)
        colesterol_ldl = random.randint(160, 190)
        glucosa = random.randint(120, 150)
        trigliceridos = random.randint(200, 300)
        
        observaciones = random.choice([
            'Paciente presenta hipertensión arterial severa. Requiere evaluación cardiológica urgente.',
            'Valores de colesterol muy elevados. Riesgo cardiovascular alto. Derivar a especialista.',
            'Obesidad grado II con hipertensión. Requiere control médico estricto.',
            'Glucosa elevada, sospecha de diabetes. Requiere exámenes complementarios.'
        ])
        
    elif nivel_riesgo == 'MEDIO':
        presion_sistolica = random.randint(130, 145)
        presion_diastolica = random.randint(85, 94)
        peso = round(random.uniform(75, 95), 1)
        altura = round(random.uniform(1.60, 1.85), 2)
        imc = peso / (altura ** 2)
        
        # Laboratorio con valores límite
        colesterol_total = random.randint(200, 239)
        colesterol_ldl = random.randint(130, 159)
        glucosa = random.randint(100, 119)
        trigliceridos = random.randint(150, 199)
        
        observaciones = random.choice([
            'Paciente con valores límite de presión arterial. Recomendar control periódico.',
            'Sobrepeso leve. Recomendar dieta y ejercicio.',
            'Colesterol en rango límite. Sugerir cambios en estilo de vida.',
            'Valores dentro de rangos aceptables pero requiere seguimiento.'
        ])
        
    else:  # BAJO
        presion_sistolica = random.randint(110, 129)
        presion_diastolica = random.randint(70, 84)
        peso = round(random.uniform(60, 85), 1)
        altura = round(random.uniform(1.60, 1.85), 2)
        imc = peso / (altura ** 2)
        
        # Laboratorio con valores normales
        colesterol_total = random.randint(150, 199)
        colesterol_ldl = random.randint(80, 129)
        glucosa = random.randint(70, 99)
        trigliceridos = random.randint(80, 149)
        
        observaciones = random.choice([
            'Paciente en buen estado general. Todos los valores dentro de rangos normales.',
            'Examen sin hallazgos patológicos. Apto para el puesto.',
            'Condición física adecuada. No se observan contraindicaciones.',
            'Resultados satisfactorios. Paciente saludable.'
        ])
    
    presion_arterial = f"{presion_sistolica}/{presion_diastolica}"
    
    # Otros valores del examen
    vision = random.choice(['20/20', '20/25', '20/30', '20/40'])
    audiometria = random.choice(['Normal', 'Leve pérdida en frecuencias altas', 'Normal bilateral'])
    
    # Laboratorio completo
    laboratorio = {
        'hematologia': {
            'hemoglobina': round(random.uniform(13, 17), 1),
            'hematocrito': round(random.uniform(40, 50), 1),
            'globulos_blancos': random.randint(4000, 11000),
            'plaquetas': random.randint(150000, 400000)
        },
        'perfil_lipidico': {
            'colesterol_total': colesterol_total,
            'colesterol_hdl': random.randint(35, 60),
            'colesterol_ldl': colesterol_ldl,
            'trigliceridos': trigliceridos
        },
        'glucosa': {
            'glucosa_basal': glucosa
        },
        'funcion_renal': {
            'creatinina': round(random.uniform(0.7, 1.3), 1),
            'urea': random.randint(15, 40),
            'acido_urico': round(random.uniform(3.5, 7.2), 1)
        },
        'funcion_hepatica': {
            'tgo': random.randint(10, 40),
            'tgp': random.randint(10, 40),
            'bilirrubina_total': round(random.uniform(0.3, 1.2), 1)
        }
    }
    
    return {
        'tipo': tipo_examen,
        'presion_arterial': presion_arterial,
        'peso': peso,
        'altura': altura,
        'imc': round(imc, 1),
        'vision': vision,
        'audiometria': audiometria,
        'laboratorio': laboratorio,
        'observaciones': observaciones
    }
