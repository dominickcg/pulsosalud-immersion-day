#!/usr/bin/env python3
"""
Script simple para generar un PDF básico compatible con Textract.
"""

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

def create_simple_pdf():
    """Crea un PDF simple con texto básico."""
    filename = "test_simple.pdf"
    c = canvas.Canvas(filename, pagesize=letter)
    
    # Agregar texto simple
    c.drawString(100, 750, "INFORME MÉDICO OCUPACIONAL")
    c.drawString(100, 720, "")
    c.drawString(100, 700, "DATOS DEL TRABAJADOR")
    c.drawString(100, 680, "Nombre: Carlos Rodríguez Martínez")
    c.drawString(100, 660, "DNI: 45678912")
    c.drawString(100, 640, "Cargo: Operador de Maquinaria Pesada")
    c.drawString(100, 620, "")
    c.drawString(100, 600, "RESULTADOS DEL EXAMEN")
    c.drawString(100, 580, "Presión Arterial: 165/102 mmHg")
    c.drawString(100, 560, "Peso: 95 kg")
    c.drawString(100, 540, "Altura: 1.70 m")
    c.drawString(100, 520, "IMC: 32.9")
    c.drawString(100, 500, "Visión: 20/40")
    c.drawString(100, 480, "Audiometría: Pérdida moderada bilateral")
    
    c.save()
    print(f"✅ Generado: {filename}")

if __name__ == "__main__":
    create_simple_pdf()
