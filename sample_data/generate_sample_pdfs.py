#!/usr/bin/env python3
"""
Script para generar PDFs de ejemplo de informes médicos ocupacionales.
Genera 3 PDFs con diferentes niveles de riesgo: BAJO, MEDIO, ALTO.

Uso:
    python generate_sample_pdfs.py

Requisitos:
    pip install reportlab
"""

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from datetime import datetime, timedelta
import os
from medical_data import BAJO_RIESGO, MEDIO_RIESGO, ALTO_RIESGO


def create_pdf_header(elements, styles, contratista, tipo_examen):
    """Crea el encabezado del PDF."""
    # Título
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=30,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph(f"INFORME MÉDICO OCUPACIONAL", title_style))
    elements.append(Spacer(1, 0.2*inch))
    
    # Información del contratista
    contratista_data = [
        ['EMPRESA CONTRATISTA', contratista['nombre']],
        ['RUC', contratista['ruc']],
        ['TIPO DE EXAMEN', tipo_examen],
        ['FECHA DE EMISIÓN', datetime.now().strftime('%d/%m/%Y')]
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


def create_trabajador_section(elements, styles, trabajador):
    """Crea la sección de datos del trabajador."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("DATOS DEL TRABAJADOR", section_style))
    
    trabajador_data = [
        ['Nombre Completo', trabajador['nombre']],
        ['DNI', trabajador['dni']],
        ['Fecha de Nacimiento', trabajador['fecha_nacimiento']],
        ['Edad', f"{trabajador['edad']} años"],
        ['Cargo', trabajador['cargo']],
    ]
    
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


def create_examen_section(elements, styles, examen):
    """Crea la sección de resultados del examen."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("RESULTADOS DEL EXAMEN MÉDICO", section_style))
    
    # Signos vitales
    vitales_data = [
        ['PARÁMETRO', 'RESULTADO', 'RANGO NORMAL'],
        ['Presión Arterial', examen['presion_arterial'], '90/60 - 120/80 mmHg'],
        ['Frecuencia Cardíaca', f"{examen['frecuencia_cardiaca']} lpm", '60 - 100 lpm'],
        ['Frecuencia Respiratoria', f"{examen['frecuencia_respiratoria']} rpm", '12 - 20 rpm'],
        ['Temperatura', f"{examen['temperatura']} °C", '36.5 - 37.5 °C'],
        ['Saturación O2', f"{examen['saturacion_oxigeno']}%", '> 95%'],
        ['Peso', f"{examen['peso']} kg", 'Variable'],
        ['Altura', f"{examen['altura']} m", 'Variable'],
        ['IMC', f"{examen['imc']:.1f}", '18.5 - 24.9'],
        ['Perímetro Abdominal', f"{examen['perimetro_abdominal']} cm", '< 102 cm (H), < 88 cm (M)'],
    ]
    
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
    
    # Exámenes complementarios
    complementarios_data = [
        ['EXAMEN', 'RESULTADO'],
        ['Visión', examen['vision']],
        ['Audiometría', examen['audiometria']],
    ]
    
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
    
    # Exámenes de laboratorio (si existen)
    if 'laboratorio' in examen and examen['laboratorio']:
        lab_data = [
            ['EXAMEN DE LABORATORIO', 'RESULTADO', 'RANGO NORMAL'],
        ]
        for item in examen['laboratorio']:
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


def create_antecedentes_section(elements, styles, antecedentes):
    """Crea la sección de antecedentes médicos."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("ANTECEDENTES MÉDICOS", section_style))
    
    ant_style = ParagraphStyle(
        'Antecedentes',
        parent=styles['Normal'],
        fontSize=10,
        alignment=TA_LEFT,
        spaceAfter=8,
        leading=14
    )
    
    elements.append(Paragraph(antecedentes, ant_style))
    elements.append(Spacer(1, 0.2*inch))


def create_examen_fisico_section(elements, styles, examen_fisico):
    """Crea la sección de examen físico."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("EXAMEN FÍSICO", section_style))
    
    # Estilo para el contenido de las celdas
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
            Paragraph(item['sistema'], cell_style_bold),
            Paragraph(item['hallazgo'], cell_style)
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


def create_examenes_complementarios_section(elements, styles, examenes):
    """Crea la sección de exámenes complementarios."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("EXÁMENES COMPLEMENTARIOS", section_style))
    
    # Estilo para el contenido de las celdas
    cell_style = ParagraphStyle(
        'CellStyle',
        parent=styles['Normal'],
        fontSize=9,
        leading=12,
        alignment=TA_LEFT
    )
    
    # Crear tabla con los exámenes usando Paragraph para ajuste automático
    exam_data = [['EXAMEN', 'RESULTADO']]
    for ex in examenes:
        exam_data.append([
            Paragraph(f"<b>{ex['nombre']}</b>", cell_style),
            Paragraph(ex['resultado'], cell_style)
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


def create_observaciones_section(elements, styles, observaciones):
    """Crea la sección de observaciones."""
    section_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=12,
        fontName='Helvetica-Bold'
    )
    
    elements.append(Paragraph("OBSERVACIONES Y RECOMENDACIONES", section_style))
    
    obs_style = ParagraphStyle(
        'Observaciones',
        parent=styles['Normal'],
        fontSize=10,
        alignment=TA_LEFT,
        spaceAfter=12,
        leading=14
    )
    
    elements.append(Paragraph(observaciones, obs_style))
    elements.append(Spacer(1, 0.3*inch))


def create_firma_section(elements, styles):
    """Crea la sección de firma."""
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


def generate_bajo_riesgo_pdf():
    """Genera PDF de informe con riesgo BAJO."""
    filename = "informe_bajo_riesgo.pdf"
    doc = SimpleDocTemplate(filename, pagesize=letter,
                           topMargin=0.5*inch, bottomMargin=0.5*inch,
                           leftMargin=0.75*inch, rightMargin=0.75*inch)
    
    elements = []
    styles = getSampleStyleSheet()
    
    data = BAJO_RIESGO
    
    create_pdf_header(elements, styles, data['contratista'], 'Examen Periódico')
    create_trabajador_section(elements, styles, data['trabajador'])
    create_antecedentes_section(elements, styles, data['antecedentes'])
    create_examen_section(elements, styles, data['examen'])
    create_examen_fisico_section(elements, styles, data['examen_fisico'])
    
    # Exámenes complementarios
    if 'examenes_adicionales' in data:
        create_examenes_complementarios_section(elements, styles, data['examenes_adicionales'])
    
    create_observaciones_section(elements, styles, data['observaciones'])
    create_firma_section(elements, styles)
    
    doc.build(elements)
    print(f"✅ Generado: {filename}")


def generate_medio_riesgo_pdf():
    """Genera PDF de informe con riesgo MEDIO."""
    filename = "informe_medio_riesgo.pdf"
    doc = SimpleDocTemplate(filename, pagesize=letter,
                           topMargin=0.5*inch, bottomMargin=0.5*inch,
                           leftMargin=0.75*inch, rightMargin=0.75*inch)
    
    elements = []
    styles = getSampleStyleSheet()
    
    data = MEDIO_RIESGO
    
    create_pdf_header(elements, styles, data['contratista'], 'Examen Periódico')
    create_trabajador_section(elements, styles, data['trabajador'])
    create_antecedentes_section(elements, styles, data['antecedentes'])
    create_examen_section(elements, styles, data['examen'])
    create_examen_fisico_section(elements, styles, data['examen_fisico'])
    
    # Exámenes complementarios
    if 'examenes_adicionales' in data:
        create_examenes_complementarios_section(elements, styles, data['examenes_adicionales'])
    
    create_observaciones_section(elements, styles, data['observaciones'])
    create_firma_section(elements, styles)
    
    doc.build(elements)
    print(f"✅ Generado: {filename}")


def generate_alto_riesgo_pdf_OLD():
    
    # Datos del contratista
    contratista = {
        'nombre': 'Minera del Norte Ltda.',
        'ruc': '20467892345'  # RUC realista para Perú
    }
    
    # Datos del trabajador
    trabajador = {
        'nombre': 'María González López',
        'dni': '41256789',  # DNI realista para Perú
        'fecha_nacimiento': '22/07/1978',
        'edad': 46,
        'cargo': 'Supervisora de Producción'
    }
    
    # Datos del examen
    examen = {
        'presion_arterial': '142/88 mmHg',
        'frecuencia_cardiaca': 82,
        'frecuencia_respiratoria': 18,
        'temperatura': 36.8,
        'peso': 78.0,
        'altura': 1.65,
        'imc': 78.0 / (1.65 ** 2),
        'vision': 'OD: 20/30, OI: 20/25 - Leve reducción',
        'audiometria': 'Pérdida auditiva leve en frecuencias altas (4000-8000 Hz) bilateral',
        'laboratorio': [
            {'nombre': 'Hemoglobina', 'resultado': '13.8 g/dL', 'rango': '12.0 - 16.0 g/dL'},
            {'nombre': 'Glucosa', 'resultado': '108 mg/dL', 'rango': '70 - 100 mg/dL'},
            {'nombre': 'Colesterol Total', 'resultado': '225 mg/dL', 'rango': '< 200 mg/dL'},
            {'nombre': 'Triglicéridos', 'resultado': '165 mg/dL', 'rango': '< 150 mg/dL'},
            {'nombre': 'Creatinina', 'resultado': '1.0 mg/dL', 'rango': '0.6 - 1.2 mg/dL'},
            {'nombre': 'Ácido Úrico', 'resultado': '6.2 mg/dL', 'rango': '2.4 - 6.0 mg/dL'},
        ]
    }
    
    observaciones = """
    La trabajadora presenta algunos parámetros que requieren seguimiento y control médico. 
    Se observa presión arterial en rango de pre-hipertensión (142/88 mmHg), lo cual requiere 
    monitoreo regular. El índice de masa corporal indica sobrepeso (IMC: 28.6), factor que 
    puede contribuir a la elevación de la presión arterial.
    
    La evaluación visual muestra una leve reducción de la agudeza visual en ojo derecho (20/30), 
    se recomienda evaluación oftalmológica para determinar necesidad de corrección óptica. 
    La audiometría revela pérdida auditiva leve en frecuencias altas, compatible con exposición 
    a ruido ocupacional, se debe reforzar el uso de protección auditiva.
    
    RECOMENDACIONES:
    - Control médico en 3 meses para seguimiento de presión arterial
    - Evaluación oftalmológica para corrección visual
    - Programa de control de peso y hábitos alimenticios
    - Reforzar uso de elementos de protección personal (EPP)
    - Continuar con audiometrías periódicas
    
    APTO PARA EL TRABAJO CON SEGUIMIENTO MÉDICO.
    """
    
    create_pdf_header(elements, styles, contratista, 'Examen Periódico')
    create_trabajador_section(elements, styles, trabajador)
    create_examen_section(elements, styles, examen)
    create_observaciones_section(elements, styles, observaciones)
    create_firma_section(elements, styles)
    
    doc.build(elements)
    print(f"✅ Generado: {filename}")


def generate_alto_riesgo_pdf():
    """Genera PDF de informe con riesgo ALTO."""
    filename = "informe_alto_riesgo.pdf"
    doc = SimpleDocTemplate(filename, pagesize=letter,
                           topMargin=0.5*inch, bottomMargin=0.5*inch,
                           leftMargin=0.75*inch, rightMargin=0.75*inch)
    
    elements = []
    styles = getSampleStyleSheet()
    
    data = ALTO_RIESGO
    
    create_pdf_header(elements, styles, data['contratista'], 'Examen Periódico')
    create_trabajador_section(elements, styles, data['trabajador'])
    create_antecedentes_section(elements, styles, data['antecedentes'])
    create_examen_section(elements, styles, data['examen'])
    create_examen_fisico_section(elements, styles, data['examen_fisico'])
    
    # Exámenes complementarios
    if 'examenes_adicionales' in data:
        create_examenes_complementarios_section(elements, styles, data['examenes_adicionales'])
    
    create_observaciones_section(elements, styles, data['observaciones'])
    create_firma_section(elements, styles)
    
    doc.build(elements)
    print(f"✅ Generado: {filename}")


def main():
    """Función principal."""
    print("\n🏥 Generando PDFs de ejemplo de informes médicos ocupacionales...\n")
    
    # Crear directorio si no existe
    os.makedirs(".", exist_ok=True)
    
    # Generar los 3 PDFs
    generate_bajo_riesgo_pdf()
    generate_medio_riesgo_pdf()
    generate_alto_riesgo_pdf()
    
    print("\n✅ Todos los PDFs han sido generados exitosamente!")
    print("\nArchivos creados:")
    print("  - informe_bajo_riesgo.pdf")
    print("  - informe_medio_riesgo.pdf")
    print("  - informe_alto_riesgo.pdf")
    print("\nPuedes subirlos a S3 usando:")
    print("  aws s3 cp informe_bajo_riesgo.pdf s3://YOUR-BUCKET/external-reports/")
    print("  aws s3 cp informe_medio_riesgo.pdf s3://YOUR-BUCKET/external-reports/")
    print("  aws s3 cp informe_alto_riesgo.pdf s3://YOUR-BUCKET/external-reports/")
    print()


if __name__ == "__main__":
    main()
