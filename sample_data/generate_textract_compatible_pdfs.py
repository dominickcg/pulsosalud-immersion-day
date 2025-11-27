#!/usr/bin/env python3
"""
Script para generar PDFs compatibles con Textract usando canvas.Canvas.
Genera informes médicos ocupacionales realistas.
"""

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from medical_data import BAJO_RIESGO, MEDIO_RIESGO, ALTO_RIESGO


def draw_header(c, y_position, contratista, tipo_examen):
    """Dibuja el encabezado del informe."""
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(letter[0]/2, y_position, "INFORME MÉDICO OCUPACIONAL")
    y_position -= 30
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "EMPRESA CONTRATISTA:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, contratista['nombre'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "RUC:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, contratista['ruc'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "TIPO DE EXAMEN:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, tipo_examen)
    y_position -= 30
    
    return y_position


def draw_trabajador(c, y_position, trabajador):
    """Dibuja la sección de datos del trabajador."""
    c.setFont("Helvetica-Bold", 12)
    c.drawString(inch, y_position, "DATOS DEL TRABAJADOR")
    y_position -= 20
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Nombre:")
    c.setFont("Helvetica", 10)
    c.drawString(2.5*inch, y_position, trabajador['nombre'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "DNI:")
    c.setFont("Helvetica", 10)
    c.drawString(2.5*inch, y_position, trabajador['dni'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Fecha de Nacimiento:")
    c.setFont("Helvetica", 10)
    c.drawString(2.5*inch, y_position, trabajador['fecha_nacimiento'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Edad:")
    c.setFont("Helvetica", 10)
    c.drawString(2.5*inch, y_position, f"{trabajador['edad']} años")
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Cargo:")
    c.setFont("Helvetica", 10)
    c.drawString(2.5*inch, y_position, trabajador['cargo'])
    y_position -= 30
    
    return y_position


def draw_examen(c, y_position, examen):
    """Dibuja la sección de resultados del examen."""
    c.setFont("Helvetica-Bold", 12)
    c.drawString(inch, y_position, "RESULTADOS DEL EXAMEN MÉDICO")
    y_position -= 20
    
    # Signos vitales
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Presión Arterial:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, examen['presion_arterial'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Frecuencia Cardíaca:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, f"{examen['frecuencia_cardiaca']} lpm")
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Peso:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, f"{examen['peso']} kg")
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Altura:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, f"{examen['altura']} m")
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "IMC:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, f"{examen['imc']:.1f}")
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Visión:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, examen['vision'])
    y_position -= 15
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, y_position, "Audiometría:")
    c.setFont("Helvetica", 10)
    c.drawString(3*inch, y_position, examen['audiometria'])
    y_position -= 30
    
    return y_position


def draw_antecedentes(c, y_position, antecedentes):
    """Dibuja la sección de antecedentes."""
    c.setFont("Helvetica-Bold", 12)
    c.drawString(inch, y_position, "ANTECEDENTES MÉDICOS")
    y_position -= 20
    
    c.setFont("Helvetica", 9)
    # Dividir el texto en líneas
    lines = antecedentes.split('\n')
    for line in lines:
        if line.strip():
            c.drawString(inch, y_position, line.strip())
            y_position -= 12
    
    y_position -= 10
    return y_position


def draw_observaciones(c, y_position, observaciones):
    """Dibuja la sección de observaciones."""
    c.setFont("Helvetica-Bold", 12)
    c.drawString(inch, y_position, "OBSERVACIONES Y RECOMENDACIONES")
    y_position -= 20
    
    c.setFont("Helvetica", 9)
    # Dividir el texto en líneas
    lines = observaciones.split('\n')
    for line in lines:
        if line.strip():
            # Manejar líneas largas
            if len(line) > 90:
                words = line.split()
                current_line = ""
                for word in words:
                    if len(current_line + word) < 90:
                        current_line += word + " "
                    else:
                        c.drawString(inch, y_position, current_line.strip())
                        y_position -= 12
                        current_line = word + " "
                if current_line:
                    c.drawString(inch, y_position, current_line.strip())
                    y_position -= 12
            else:
                c.drawString(inch, y_position, line.strip())
                y_position -= 12
    
    return y_position


def generate_pdf(filename, data, tipo_examen):
    """Genera un PDF completo."""
    c = canvas.Canvas(filename, pagesize=letter)
    y_position = letter[1] - inch
    
    # Header
    y_position = draw_header(c, y_position, data['contratista'], tipo_examen)
    
    # Trabajador
    y_position = draw_trabajador(c, y_position, data['trabajador'])
    
    # Antecedentes
    if y_position < 3*inch:
        c.showPage()
        y_position = letter[1] - inch
    y_position = draw_antecedentes(c, y_position, data['antecedentes'])
    
    # Examen
    if y_position < 4*inch:
        c.showPage()
        y_position = letter[1] - inch
    y_position = draw_examen(c, y_position, data['examen'])
    
    # Observaciones
    if y_position < 4*inch:
        c.showPage()
        y_position = letter[1] - inch
    y_position = draw_observaciones(c, y_position, data['observaciones'])
    
    # Firma
    y_position -= 40
    c.setFont("Helvetica", 10)
    c.drawCentredString(letter[0]/2, y_position, "_" * 40)
    y_position -= 15
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(letter[0]/2, y_position, "Dr. Roberto Sánchez Muñoz")
    y_position -= 15
    c.setFont("Helvetica", 10)
    c.drawCentredString(letter[0]/2, y_position, "Médico Ocupacional")
    y_position -= 15
    c.drawCentredString(letter[0]/2, y_position, "Reg. Médico: 12345-6")
    
    c.save()
    print(f"✅ Generado: {filename}")


def main():
    """Función principal."""
    print("\n🏥 Generando PDFs compatibles con Textract...\n")
    
    generate_pdf("informe_bajo_riesgo.pdf", BAJO_RIESGO, "Examen Periódico")
    generate_pdf("informe_medio_riesgo.pdf", MEDIO_RIESGO, "Examen Periódico")
    generate_pdf("informe_alto_riesgo.pdf", ALTO_RIESGO, "Examen Periódico")
    
    print("\n✅ Todos los PDFs han sido generados exitosamente!")
    print("\nArchivos creados:")
    print("  - informe_bajo_riesgo.pdf")
    print("  - informe_medio_riesgo.pdf")
    print("  - informe_alto_riesgo.pdf")
    print()


if __name__ == "__main__":
    main()
