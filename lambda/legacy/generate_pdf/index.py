import json
import os
import boto3
from datetime import datetime
from io import BytesIO

# ReportLab imports
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

# Clientes AWS
secretsmanager = boto3.client('secretsmanager')
rds_data = boto3.client('rds-data')
s3_client = boto3.client('s3')

# Variables de entorno
DB_SECRET_ARN = os.environ['DB_SECRET_ARN']
DB_CLUSTER_ARN = os.environ['DB_CLUSTER_ARN']
DATABASE_NAME = os.environ['DATABASE_NAME']
BUCKET_NAME = os.environ['BUCKET_NAME']


def handler(event, context):
    """
    Lambda para generar PDFs profesionales de informes médicos.
    Lee datos de Aurora y genera un PDF con diseño atractivo.
    """
    try:
        # Obtener informe_id del evento
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event
        
        informe_id = body.get('informe_id')
        
        if not informe_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'informe_id is required'})
            }
        
        # Leer datos del informe desde Aurora
        informe_data = get_informe_from_aurora(informe_id)
        
        if not informe_data:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Informe not found'})
            }
        
        # Generar PDF
        pdf_buffer = generar_pdf_profesional(informe_data)
        
        # Subir a S3
        pdf_url = upload_to_s3(pdf_buffer, informe_id)
        
        # Actualizar Aurora con la ruta del PDF
        update_pdf_path_in_aurora(informe_id, pdf_url)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'pdf_url': pdf_url,
                'message': 'PDF generado exitosamente'
            })
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


def get_informe_from_aurora(informe_id):
    """Lee los datos completos del informe desde Aurora."""
    
    sql = """
        SELECT 
            im.id, im.tipo_examen, im.fecha_examen,
            im.presion_arterial, im.frecuencia_cardiaca, im.frecuencia_respiratoria,
            im.temperatura, im.saturacion_oxigeno, im.peso, im.altura, im.imc,
            im.perimetro_abdominal, im.vision, im.audiometria,
            im.antecedentes_medicos, im.examen_fisico, im.examenes_adicionales,
            im.observaciones,
            t.nombre as trabajador_nombre, t.documento as trabajador_documento,
            t.fecha_nacimiento, t.edad, t.cargo,
            c.nombre as contratista_nombre, c.ruc as contratista_ruc, c.email as contratista_email,
            lr.hemoglobina, lr.glucosa_basal, lr.colesterol_total, lr.trigliceridos,
            lr.creatinina, lr.acido_urico
        FROM informes_medicos im
        JOIN trabajadores t ON im.trabajador_id = t.id
        JOIN contratistas c ON im.contratista_id = c.id
        LEFT JOIN laboratorio_resultados lr ON im.id = lr.informe_id
        WHERE im.id = :informe_id
    """
    
    response = rds_data.execute_statement(
        secretArn=DB_SECRET_ARN,
        resourceArn=DB_CLUSTER_ARN,
        database=DATABASE_NAME,
        sql=sql,
        parameters=[
            {'name': 'informe_id', 'value': {'longValue': int(informe_id)}}
        ]
    )
    
    if not response['records']:
        return None
    
    record = response['records'][0]
    
    # Convertir el record a dict
    data = {
        'id': record[0]['longValue'],
        'tipo_examen': record[1]['stringValue'],
        'fecha_examen': record[2]['stringValue'],
        'presion_arterial': record[3].get('stringValue', ''),
        'frecuencia_cardiaca': record[4].get('longValue', 0),
        'frecuencia_respiratoria': record[5].get('longValue', 0),
        'temperatura': record[6].get('doubleValue', 0),
        'saturacion_oxigeno': record[7].get('longValue', 0),
        'peso': record[8].get('doubleValue', 0),
        'altura': record[9].get('doubleValue', 0),
        'imc': record[10].get('doubleValue', 0),
        'perimetro_abdominal': record[11].get('longValue', 0),
        'vision': record[12].get('stringValue', ''),
        'audiometria': record[13].get('stringValue', ''),
        'antecedentes_medicos': record[14].get('stringValue', ''),
        'examen_fisico': record[15].get('stringValue', '[]'),
        'examenes_adicionales': record[16].get('stringValue', '[]'),
        'observaciones': record[17].get('stringValue', ''),
        'trabajador_nombre': record[18]['stringValue'],
        'trabajador_documento': record[19]['stringValue'],
        'trabajador_fecha_nacimiento': record[20].get('stringValue', ''),
        'trabajador_edad': record[21].get('longValue', 0),
        'trabajador_cargo': record[22].get('stringValue', ''),
        'contratista_nombre': record[23]['stringValue'],
        'contratista_ruc': record[24].get('stringValue', ''),
        'contratista_email': record[25]['stringValue'],
    }
    
    # Agregar datos de laboratorio si existen
    laboratorio = []
    if record[26].get('doubleValue'):  # hemoglobina
        laboratorio.append({
            'nombre': 'Hemoglobina',
            'resultado': f"{record[26]['doubleValue']} g/dL",
            'rango': '12.0 - 16.0 g/dL'
        })
    if record[27].get('longValue'):  # glucosa
        laboratorio.append({
            'nombre': 'Glucosa',
            'resultado': f"{record[27]['longValue']} mg/dL",
            'rango': '70 - 100 mg/dL'
        })
    if record[28].get('longValue'):  # colesterol
        laboratorio.append({
            'nombre': 'Colesterol Total',
            'resultado': f"{record[28]['longValue']} mg/dL",
            'rango': '< 200 mg/dL'
        })
    if record[29].get('longValue'):  # trigliceridos
        laboratorio.append({
            'nombre': 'Triglicéridos',
            'resultado': f"{record[29]['longValue']} mg/dL",
            'rango': '< 150 mg/dL'
        })
    if record[30].get('doubleValue'):  # creatinina
        laboratorio.append({
            'nombre': 'Creatinina',
            'resultado': f"{record[30]['doubleValue']} mg/dL",
            'rango': '0.6 - 1.2 mg/dL'
        })
    if record[31].get('doubleValue'):  # acido_urico
        laboratorio.append({
            'nombre': 'Ácido Úrico',
            'resultado': f"{record[31]['doubleValue']} mg/dL",
            'rango': '2.4 - 6.0 mg/dL'
        })
    
    data['laboratorio'] = laboratorio
    
    return data


def generar_pdf_profesional(data):
    """
    Genera un PDF profesional con diseño atractivo y completo.
    Usa ReportLab con platypus para layouts avanzados.
    """
    
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=letter, 
        topMargin=0.5*inch, 
        bottomMargin=0.5*inch,
        leftMargin=0.75*inch,
        rightMargin=0.75*inch
    )
    
    # Contenedor para los elementos del PDF
    elements = []
    
    # Estilos
    styles = getSampleStyleSheet()
    
    # Estilo personalizado para el título
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=30,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    # Estilo para subtítulos
    subtitle_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    # ========================================
    # ENCABEZADO
    # ========================================
    elements.append(Paragraph("INFORME MÉDICO OCUPACIONAL", title_style))
    elements.append(Spacer(1, 0.2*inch))
    
    # Información del contratista
    contratista_data = [
        ['EMPRESA CONTRATISTA', data['contratista_nombre']],
        ['RUC', data.get('contratista_ruc', 'N/A')],
        ['TIPO DE EXAMEN', data['tipo_examen']],
        ['FECHA DE EMISIÓN', datetime.fromisoformat(data['fecha_examen']).strftime('%d/%m/%Y')]
    ]
    
    contratista_table = Table(contratista_data, colWidths=[2.5*inch, 4*inch])
    contratista_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8f4f8')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(contratista_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # ========================================
    # DATOS DEL TRABAJADOR
    # ========================================
    elements.append(Paragraph("DATOS DEL TRABAJADOR", subtitle_style))
    
    trabajador_data = [
        ['Nombre Completo', data['trabajador_nombre']],
        ['DNI', data['trabajador_documento']],
    ]
    
    if data.get('trabajador_fecha_nacimiento'):
        trabajador_data.append(['Fecha de Nacimiento', data['trabajador_fecha_nacimiento']])
    
    if data.get('trabajador_edad'):
        trabajador_data.append(['Edad', f"{data['trabajador_edad']} años"])
    
    if data.get('trabajador_cargo'):
        trabajador_data.append(['Cargo', data['trabajador_cargo']])
    
    trabajador_table = Table(trabajador_data, colWidths=[2.5*inch, 4*inch])
    trabajador_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#f5f5f5')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(trabajador_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # ========================================
    # ANTECEDENTES MÉDICOS
    # ========================================
    if data.get('antecedentes_medicos'):
        elements.append(Paragraph("ANTECEDENTES MÉDICOS", subtitle_style))
        
        ant_style = ParagraphStyle(
            'Antecedentes',
            parent=styles['Normal'],
            fontSize=10,
            alignment=TA_LEFT,
            spaceAfter=8,
            leading=14
        )
        
        elements.append(Paragraph(data['antecedentes_medicos'], ant_style))
        elements.append(Spacer(1, 0.2*inch))
    
    # ========================================
    # RESULTADOS DEL EXAMEN MÉDICO
    # ========================================
    elements.append(Paragraph("RESULTADOS DEL EXAMEN MÉDICO", subtitle_style))
    
    # Signos vitales
    vitales_data = [
        ['PARÁMETRO', 'RESULTADO', 'RANGO NORMAL'],
    ]
    
    if data.get('presion_arterial'):
        vitales_data.append(['Presión Arterial', data['presion_arterial'], '90/60 - 120/80 mmHg'])
    
    if data.get('frecuencia_cardiaca'):
        vitales_data.append(['Frecuencia Cardíaca', f"{data['frecuencia_cardiaca']} lpm", '60 - 100 lpm'])
    
    if data.get('frecuencia_respiratoria'):
        vitales_data.append(['Frecuencia Respiratoria', f"{data['frecuencia_respiratoria']} rpm", '12 - 20 rpm'])
    
    if data.get('temperatura'):
        vitales_data.append(['Temperatura', f"{data['temperatura']} °C", '36.5 - 37.5 °C'])
    
    if data.get('saturacion_oxigeno'):
        vitales_data.append(['Saturación O2', f"{data['saturacion_oxigeno']}%", '> 95%'])
    
    if data.get('peso'):
        vitales_data.append(['Peso', f"{data['peso']} kg", 'Variable'])
    
    if data.get('altura'):
        vitales_data.append(['Altura', f"{data['altura']} m", 'Variable'])
    
    if data.get('imc'):
        vitales_data.append(['IMC', f"{data['imc']:.1f}", '18.5 - 24.9'])
    
    if data.get('perimetro_abdominal'):
        vitales_data.append(['Perímetro Abdominal', f"{data['perimetro_abdominal']} cm", '< 102 cm (H), < 88 cm (M)'])
    
    if len(vitales_data) > 1:  # Si hay datos además del encabezado
        vitales_table = Table(vitales_data, colWidths=[2.2*inch, 2.2*inch, 2.2*inch])
        vitales_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5490')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        
        elements.append(vitales_table)
        elements.append(Spacer(1, 0.2*inch))
    
    # Exámenes complementarios básicos
    if data.get('vision') or data.get('audiometria'):
        complementarios_data = [
            ['EXAMEN', 'RESULTADO'],
        ]
        
        if data.get('vision'):
            complementarios_data.append(['Visión', data['vision']])
        
        if data.get('audiometria'):
            complementarios_data.append(['Audiometría', data['audiometria']])
        
        complementarios_table = Table(complementarios_data, colWidths=[3*inch, 3.6*inch])
        complementarios_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5490')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        
        elements.append(complementarios_table)
        elements.append(Spacer(1, 0.2*inch))
    
    # Exámenes de laboratorio
    if data.get('laboratorio') and len(data['laboratorio']) > 0:
        lab_data = [
            ['EXAMEN DE LABORATORIO', 'RESULTADO', 'RANGO NORMAL'],
        ]
        for item in data['laboratorio']:
            lab_data.append([item['nombre'], item['resultado'], item['rango']])
        
        lab_table = Table(lab_data, colWidths=[2.2*inch, 2.2*inch, 2.2*inch])
        lab_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5490')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        
        elements.append(lab_table)
    
    elements.append(Spacer(1, 0.3*inch))
    
    # ========================================
    # EXAMEN FÍSICO
    # ========================================
    if data.get('examen_fisico'):
        try:
            examen_fisico = json.loads(data['examen_fisico']) if isinstance(data['examen_fisico'], str) else data['examen_fisico']
            
            if examen_fisico and len(examen_fisico) > 0:
                elements.append(Paragraph("EXAMEN FÍSICO", subtitle_style))
                
                cell_style = ParagraphStyle(
                    'CellStyle',
                    parent=styles['Normal'],
                    fontSize=9,
                    leading=11,
                    alignment=TA_LEFT
                )
                
                cell_style_bold = ParagraphStyle(
                    'CellStyleBold',
                    parent=styles['Normal'],
                    fontSize=9,
                    leading=11,
                    alignment=TA_LEFT,
                    fontName='Helvetica-Bold'
                )
                
                fisico_data = []
                for item in examen_fisico:
                    fisico_data.append([
                        Paragraph(item.get('sistema', ''), cell_style_bold),
                        Paragraph(item.get('hallazgo', ''), cell_style)
                    ])
                
                fisico_table = Table(fisico_data, colWidths=[2*inch, 4.6*inch])
                fisico_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#f5f5f5')),
                    ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('GRID', (0, 0), (-1, -1), 1, colors.grey),
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 8),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                    ('TOPPADDING', (0, 0), (-1, -1), 6),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                ]))
                
                elements.append(fisico_table)
                elements.append(Spacer(1, 0.2*inch))
        except:
            pass
    
    # ========================================
    # EXÁMENES COMPLEMENTARIOS ADICIONALES
    # ========================================
    if data.get('examenes_adicionales'):
        try:
            examenes_adicionales = json.loads(data['examenes_adicionales']) if isinstance(data['examenes_adicionales'], str) else data['examenes_adicionales']
            
            if examenes_adicionales and len(examenes_adicionales) > 0:
                elements.append(Paragraph("EXÁMENES COMPLEMENTARIOS", subtitle_style))
                
                cell_style = ParagraphStyle(
                    'CellStyle',
                    parent=styles['Normal'],
                    fontSize=9,
                    leading=12,
                    alignment=TA_LEFT
                )
                
                exam_data = [['EXAMEN', 'RESULTADO']]
                for ex in examenes_adicionales:
                    exam_data.append([
                        Paragraph(f"<b>{ex.get('nombre', '')}</b>", cell_style),
                        Paragraph(ex.get('resultado', ''), cell_style)
                    ])
                
                exam_table = Table(exam_data, colWidths=[2.2*inch, 4.4*inch])
                exam_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5490')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 11),
                    ('GRID', (0, 0), (-1, -1), 1, colors.grey),
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 8),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                    ('TOPPADDING', (0, 0), (-1, -1), 8),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ]))
                
                elements.append(exam_table)
                elements.append(Spacer(1, 0.3*inch))
        except:
            pass
    
    # ========================================
    # OBSERVACIONES Y RECOMENDACIONES
    # ========================================
    if data.get('observaciones'):
        elements.append(Paragraph("OBSERVACIONES Y RECOMENDACIONES", subtitle_style))
        
        obs_style = ParagraphStyle(
            'Observaciones',
            parent=styles['Normal'],
            fontSize=10,
            alignment=TA_LEFT,
            spaceAfter=12,
            leading=14
        )
        
        elements.append(Paragraph(data['observaciones'], obs_style))
        elements.append(Spacer(1, 0.3*inch))
    
    # ========================================
    # PIE DE PÁGINA - FIRMA
    # ========================================
    elements.append(Spacer(1, 0.5*inch))
    
    firma_data = [
        ['_' * 40],
        ['Dr. Roberto Sánchez Muñoz'],
        ['Médico Ocupacional'],
        ['Reg. Médico: 12345-6']
    ]
    
    firma_table = Table(firma_data, colWidths=[3*inch])
    firma_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 1), (0, 1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    
    elements.append(firma_table)
    
    # Construir el PDF
    doc.build(elements)
    
    buffer.seek(0)
    return buffer


def upload_to_s3(pdf_buffer, informe_id):
    """Sube el PDF a S3 y retorna la URL."""
    
    # Generar ruta con estructura de carpetas por fecha
    now = datetime.now()
    s3_key = f"legacy-reports/{now.year}/{now.month:02d}/informe-{informe_id}.pdf"
    
    # Subir a S3
    s3_client.put_object(
        Bucket=BUCKET_NAME,
        Key=s3_key,
        Body=pdf_buffer.getvalue(),
        ContentType='application/pdf'
    )
    
    # Retornar URL
    pdf_url = f"s3://{BUCKET_NAME}/{s3_key}"
    return pdf_url


def update_pdf_path_in_aurora(informe_id, pdf_url):
    """Actualiza el registro en Aurora con la ruta del PDF."""
    
    sql = """
        UPDATE informes_medicos
        SET pdf_s3_path = :pdf_url
        WHERE id = :informe_id
    """
    
    rds_data.execute_statement(
        secretArn=DB_SECRET_ARN,
        resourceArn=DB_CLUSTER_ARN,
        database=DATABASE_NAME,
        sql=sql,
        parameters=[
            {'name': 'pdf_url', 'value': {'stringValue': pdf_url}},
            {'name': 'informe_id', 'value': {'longValue': int(informe_id)}}
        ]
    )
