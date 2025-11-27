"""
Datos médicos completos para los informes de ejemplo.
"""

# Datos para informe de RIESGO BAJO
BAJO_RIESGO = {
    'contratista': {
        'nombre': 'Constructora Los Andes S.A.',
        'ruc': '20518734629'
    },
    'trabajador': {
        'nombre': 'Juan Pérez Gómez',
        'dni': '43567821',
        'fecha_nacimiento': '15/03/1985',
        'edad': 39,
        'cargo': 'Operador de Maquinaria'
    },
    'antecedentes': 'Sin antecedentes patológicos de importancia. No refiere alergias medicamentosas. No consume tabaco ni alcohol. Practica actividad física regularmente (3 veces por semana).',
    'examen': {
        'presion_arterial': '118/78 mmHg',
        'frecuencia_cardiaca': 72,
        'frecuencia_respiratoria': 16,
        'temperatura': 36.7,
        'saturacion_oxigeno': 98,
        'peso': 72.5,
        'altura': 1.75,
        'imc': 23.7,
        'perimetro_abdominal': 85,
        'vision': 'OD: 20/20, OI: 20/20 - Agudeza visual normal',
        'audiometria': 'Audición normal en todas las frecuencias (500-8000 Hz) bilateral',
        'laboratorio': [
            {'nombre': 'Hemoglobina', 'resultado': '15.2 g/dL', 'rango': '13.5 - 17.5 g/dL'},
            {'nombre': 'Hematocrito', 'resultado': '45%', 'rango': '40 - 50%'},
            {'nombre': 'Leucocitos', 'resultado': '7,200/mm³', 'rango': '4,000 - 11,000/mm³'},
            {'nombre': 'Plaquetas', 'resultado': '250,000/mm³', 'rango': '150,000 - 400,000/mm³'},
            {'nombre': 'Glucosa en ayunas', 'resultado': '92 mg/dL', 'rango': '70 - 100 mg/dL'},
            {'nombre': 'Colesterol Total', 'resultado': '185 mg/dL', 'rango': '< 200 mg/dL'},
            {'nombre': 'HDL Colesterol', 'resultado': '52 mg/dL', 'rango': '> 40 mg/dL'},
            {'nombre': 'LDL Colesterol', 'resultado': '110 mg/dL', 'rango': '< 130 mg/dL'},
            {'nombre': 'Triglicéridos', 'resultado': '110 mg/dL', 'rango': '< 150 mg/dL'},
            {'nombre': 'Creatinina', 'resultado': '0.9 mg/dL', 'rango': '0.7 - 1.3 mg/dL'},
            {'nombre': 'Urea', 'resultado': '32 mg/dL', 'rango': '15 - 45 mg/dL'},
            {'nombre': 'TGO (AST)', 'resultado': '28 U/L', 'rango': '< 40 U/L'},
            {'nombre': 'TGP (ALT)', 'resultado': '32 U/L', 'rango': '< 41 U/L'},
        ]
    },
    'examen_fisico': [
        {'sistema': 'Aspecto General', 'hallazgo': 'Buen estado general, bien hidratado, bien nutrido'},
        {'sistema': 'Cabeza y Cuello', 'hallazgo': 'Normocéfalo, cuello simétrico, sin adenopatías'},
        {'sistema': 'Tórax y Pulmones', 'hallazgo': 'Tórax simétrico, murmullo vesicular conservado, sin ruidos agregados'},
        {'sistema': 'Cardiovascular', 'hallazgo': 'Ruidos cardíacos rítmicos, sin soplos ni galope'},
        {'sistema': 'Abdomen', 'hallazgo': 'Blando, depresible, no doloroso, ruidos hidroaéreos presentes'},
        {'sistema': 'Extremidades', 'hallazgo': 'Sin edemas, pulsos periféricos presentes y simétricos'},
        {'sistema': 'Neurológico', 'hallazgo': 'Consciente, orientado, reflejos osteotendinosos normales'},
        {'sistema': 'Piel y Faneras', 'hallazgo': 'Piel de coloración y temperatura normal, sin lesiones'},
    ],
    'examenes_adicionales': [
        {'nombre': 'Radiografía de Tórax', 'resultado': 'Campos pulmonares limpios, silueta cardíaca normal'},
        {'nombre': 'Electrocardiograma', 'resultado': 'Ritmo sinusal normal, FC: 72 lpm, sin alteraciones'},
        {'nombre': 'Espirometría', 'resultado': 'FEV1: 95%, FVC: 98% - Función pulmonar normal'},
    ],
    'observaciones': '''El trabajador presenta un excelente estado de salud general. Todos los parámetros vitales se encuentran dentro de rangos normales. La presión arterial es óptima (118/78 mmHg), el índice de masa corporal está en rango saludable (IMC: 23.7), y tanto la visión como la audiometría muestran resultados normales sin alteraciones.

Los exámenes de laboratorio revelan valores completamente normales en perfil hematológico, metabólico, lipídico y hepático. La radiografía de tórax y el electrocardiograma no muestran alteraciones. La espirometría confirma una función pulmonar normal.

El examen físico completo no evidencia hallazgos patológicos. El trabajador mantiene hábitos de vida saludables con actividad física regular y sin consumo de sustancias nocivas.

No se observan contraindicaciones para el desempeño de sus funciones laborales. Se recomienda mantener hábitos saludables y continuar con controles médicos periódicos según lo establecido en el programa de vigilancia ocupacional.

CONCLUSIÓN: APTO PARA EL TRABAJO SIN RESTRICCIONES.'''
}

# Datos para informe de RIESGO MEDIO
MEDIO_RIESGO = {
    'contratista': {
        'nombre': 'Minera del Norte Ltda.',
        'ruc': '20467892345'
    },
    'trabajador': {
        'nombre': 'María González López',
        'dni': '41256789',
        'fecha_nacimiento': '22/07/1978',
        'edad': 46,
        'cargo': 'Supervisora de Producción'
    },
    'antecedentes': 'Hipertensión arterial diagnosticada hace 2 años, en tratamiento irregular. Madre con diabetes mellitus tipo 2. No refiere alergias. Sedentarismo. Consumo ocasional de alcohol.',
    'examen': {
        'presion_arterial': '142/88 mmHg',
        'frecuencia_cardiaca': 82,
        'frecuencia_respiratoria': 18,
        'temperatura': 36.8,
        'saturacion_oxigeno': 97,
        'peso': 78.0,
        'altura': 1.65,
        'imc': 28.6,
        'perimetro_abdominal': 95,
        'vision': 'OD: 20/30, OI: 20/25 - Leve reducción de agudeza visual',
        'audiometria': 'Pérdida auditiva leve en frecuencias altas (4000-8000 Hz) bilateral',
        'laboratorio': [
            {'nombre': 'Hemoglobina', 'resultado': '13.8 g/dL', 'rango': '12.0 - 16.0 g/dL'},
            {'nombre': 'Hematocrito', 'resultado': '41%', 'rango': '36 - 46%'},
            {'nombre': 'Leucocitos', 'resultado': '8,500/mm³', 'rango': '4,000 - 11,000/mm³'},
            {'nombre': 'Plaquetas', 'resultado': '280,000/mm³', 'rango': '150,000 - 400,000/mm³'},
            {'nombre': 'Glucosa en ayunas', 'resultado': '108 mg/dL', 'rango': '70 - 100 mg/dL'},
            {'nombre': 'Colesterol Total', 'resultado': '225 mg/dL', 'rango': '< 200 mg/dL'},
            {'nombre': 'HDL Colesterol', 'resultado': '38 mg/dL', 'rango': '> 40 mg/dL'},
            {'nombre': 'LDL Colesterol', 'resultado': '152 mg/dL', 'rango': '< 130 mg/dL'},
            {'nombre': 'Triglicéridos', 'resultado': '165 mg/dL', 'rango': '< 150 mg/dL'},
            {'nombre': 'Creatinina', 'resultado': '1.0 mg/dL', 'rango': '0.6 - 1.2 mg/dL'},
            {'nombre': 'Urea', 'resultado': '38 mg/dL', 'rango': '15 - 45 mg/dL'},
            {'nombre': 'Ácido Úrico', 'resultado': '6.2 mg/dL', 'rango': '2.4 - 6.0 mg/dL'},
            {'nombre': 'TGO (AST)', 'resultado': '35 U/L', 'rango': '< 40 U/L'},
            {'nombre': 'TGP (ALT)', 'resultado': '42 U/L', 'rango': '< 41 U/L'},
        ]
    },
    'examen_fisico': [
        {'sistema': 'Aspecto General', 'hallazgo': 'Regular estado general, sobrepeso evidente'},
        {'sistema': 'Cabeza y Cuello', 'hallazgo': 'Normocéfalo, cuello corto, sin adenopatías'},
        {'sistema': 'Tórax y Pulmones', 'hallazgo': 'Tórax simétrico, murmullo vesicular disminuido en bases'},
        {'sistema': 'Cardiovascular', 'hallazgo': 'Ruidos cardíacos rítmicos, sin soplos, FC: 82 lpm'},
        {'sistema': 'Abdomen', 'hallazgo': 'Globuloso, blando, depresible, sin masas palpables'},
        {'sistema': 'Extremidades', 'hallazgo': 'Edema leve en miembros inferiores, pulsos presentes'},
        {'sistema': 'Neurológico', 'hallazgo': 'Consciente, orientada, reflejos normales'},
        {'sistema': 'Piel y Faneras', 'hallazgo': 'Piel normal, sin lesiones significativas'},
    ],
    'examenes_adicionales': [
        {'nombre': 'Radiografía de Tórax', 'resultado': 'Índice cardiotorácico en límite superior, campos pulmonares conservados'},
        {'nombre': 'Electrocardiograma', 'resultado': 'Ritmo sinusal, FC: 82 lpm, signos de sobrecarga ventricular izquierda leve'},
        {'nombre': 'Espirometría', 'resultado': 'FEV1: 82%, FVC: 85% - Patrón restrictivo leve'},
    ],
    'observaciones': '''La trabajadora presenta algunos parámetros que requieren seguimiento y control médico. Se observa presión arterial en rango de pre-hipertensión (142/88 mmHg), lo cual requiere monitoreo regular y optimización del tratamiento antihipertensivo. El índice de masa corporal indica sobrepeso (IMC: 28.6), factor que puede contribuir a la elevación de la presión arterial y otros factores de riesgo cardiovascular.

Los exámenes de laboratorio muestran glucosa en ayunas elevada (108 mg/dL), perfil lipídico alterado con colesterol total elevado (225 mg/dL), HDL bajo (38 mg/dL) y LDL elevado (152 mg/dL), configurando un perfil de riesgo cardiovascular que requiere intervención. El ácido úrico está ligeramente elevado.

La evaluación visual muestra una leve reducción de la agudeza visual en ojo derecho (20/30), se recomienda evaluación oftalmológica para determinar necesidad de corrección óptica. La audiometría revela pérdida auditiva leve en frecuencias altas, compatible con exposición a ruido ocupacional, se debe reforzar el uso de protección auditiva.

El electrocardiograma muestra signos de sobrecarga ventricular izquierda leve, secundaria a hipertensión arterial. La espirometría evidencia un patrón restrictivo leve, probablemente relacionado con el sobrepeso.

RECOMENDACIONES:
- Control médico en 3 meses para seguimiento de presión arterial y ajuste de tratamiento
- Evaluación oftalmológica para corrección visual
- Programa de control de peso y modificación de hábitos alimenticios
- Inicio de actividad física supervisada
- Control de perfil lipídico y glucosa
- Reforzar uso de elementos de protección personal (EPP)
- Continuar con audiometrías periódicas

CONCLUSIÓN: APTO PARA EL TRABAJO CON SEGUIMIENTO MÉDICO Y RESTRICCIONES MENORES.'''
}

# Datos para informe de RIESGO ALTO  
ALTO_RIESGO = {
    'contratista': {
        'nombre': 'Transportes Rápidos del Sur S.A.',
        'ruc': '20392847561'
    },
    'trabajador': {
        'nombre': 'Carlos Rodríguez Martínez',
        'dni': '09876543',
        'fecha_nacimiento': '10/11/1972',
        'edad': 52,
        'cargo': 'Conductor de Camión'
    },
    'antecedentes': 'Hipertensión arterial de 10 años de evolución, mal controlada. Diabetes mellitus tipo 2 diagnosticada hace 5 años. Dislipidemia. Padre falleció por infarto agudo de miocardio. Tabaquismo activo (20 cigarrillos/día por 30 años). Sedentarismo.',
    'examen': {
        'presion_arterial': '165/102 mmHg',
        'frecuencia_cardiaca': 88,
        'frecuencia_respiratoria': 20,
        'temperatura': 37.0,
        'saturacion_oxigeno': 95,
        'peso': 95.0,
        'altura': 1.70,
        'imc': 32.9,
        'perimetro_abdominal': 108,
        'vision': 'OD: 20/40, OI: 20/40 - Reducción significativa de agudeza visual bilateral',
        'audiometria': 'Pérdida auditiva moderada bilateral en frecuencias medias y altas',
        'laboratorio': [
            {'nombre': 'Hemoglobina', 'resultado': '16.8 g/dL', 'rango': '13.5 - 17.5 g/dL'},
            {'nombre': 'Hematocrito', 'resultado': '50%', 'rango': '40 - 50%'},
            {'nombre': 'Leucocitos', 'resultado': '9,800/mm³', 'rango': '4,000 - 11,000/mm³'},
            {'nombre': 'Plaquetas', 'resultado': '320,000/mm³', 'rango': '150,000 - 400,000/mm³'},
            {'nombre': 'Glucosa en ayunas', 'resultado': '178 mg/dL', 'rango': '70 - 100 mg/dL'},
            {'nombre': 'HbA1c', 'resultado': '8.2%', 'rango': '< 5.7%'},
            {'nombre': 'Colesterol Total', 'resultado': '268 mg/dL', 'rango': '< 200 mg/dL'},
            {'nombre': 'HDL Colesterol', 'resultado': '32 mg/dL', 'rango': '> 40 mg/dL'},
            {'nombre': 'LDL Colesterol', 'resultado': '187 mg/dL', 'rango': '< 130 mg/dL'},
            {'nombre': 'Triglicéridos', 'resultado': '245 mg/dL', 'rango': '< 150 mg/dL'},
            {'nombre': 'Creatinina', 'resultado': '1.6 mg/dL', 'rango': '0.7 - 1.3 mg/dL'},
            {'nombre': 'Urea', 'resultado': '52 mg/dL', 'rango': '15 - 45 mg/dL'},
            {'nombre': 'Ácido Úrico', 'resultado': '8.5 mg/dL', 'rango': '3.5 - 7.2 mg/dL'},
            {'nombre': 'TGO (AST)', 'resultado': '48 U/L', 'rango': '< 40 U/L'},
            {'nombre': 'TGP (ALT)', 'resultado': '56 U/L', 'rango': '< 41 U/L'},
            {'nombre': 'Microalbuminuria', 'resultado': '85 mg/24h', 'rango': '< 30 mg/24h'},
        ]
    },
    'examen_fisico': [
        {'sistema': 'Aspecto General', 'hallazgo': 'Mal estado general, obesidad grado I, facies de enfermedad crónica'},
        {'sistema': 'Cabeza y Cuello', 'hallazgo': 'Normocéfalo, cuello corto, ingurgitación yugular leve'},
        {'sistema': 'Tórax y Pulmones', 'hallazgo': 'Tórax en tonel, murmullo vesicular disminuido, estertores crepitantes en bases'},
        {'sistema': 'Cardiovascular', 'hallazgo': 'Ruidos cardíacos rítmicos, soplo sistólico grado II/VI, FC: 88 lpm'},
        {'sistema': 'Abdomen', 'hallazgo': 'Globuloso, tenso, hepatomegalia leve, dolor a la palpación profunda'},
        {'sistema': 'Extremidades', 'hallazgo': 'Edema ++/+++ en miembros inferiores, pulsos pedios débiles'},
        {'sistema': 'Neurológico', 'hallazgo': 'Consciente, orientado, disminución de sensibilidad en pies'},
        {'sistema': 'Piel y Faneras', 'hallazgo': 'Piel seca, acantosis nigricans en cuello, úlcera en pie derecho'},
    ],
    'examenes_adicionales': [
        {'nombre': 'Radiografía de Tórax', 'resultado': 'Cardiomegalia, índice cardiotorácico 0.58, congestión pulmonar leve'},
        {'nombre': 'Electrocardiograma', 'resultado': 'Ritmo sinusal, FC: 88 lpm, hipertrofia ventricular izquierda, alteraciones de repolarización'},
        {'nombre': 'Espirometría', 'resultado': 'FEV1: 68%, FVC: 72% - Patrón obstructivo moderado'},
        {'nombre': 'Fondo de Ojo', 'resultado': 'Retinopatía hipertensiva grado II, microaneurismas compatibles con retinopatía diabética'},
    ],
    'observaciones': '''El trabajador presenta múltiples factores de riesgo que requieren ATENCIÓN MÉDICA INMEDIATA. Se detecta hipertensión arterial severa (165/102 mmHg), valor que supera significativamente los límites normales y representa un riesgo cardiovascular muy alto. El índice de masa corporal indica obesidad grado I (IMC: 32.9), factor que agrava significativamente todas las condiciones crónicas.

Los exámenes de laboratorio revelan diabetes mellitus descompensada con glucosa de 178 mg/dL y HbA1c de 8.2%, indicando mal control metabólico crónico. El perfil lipídico está severamente alterado con colesterol total de 268 mg/dL, LDL de 187 mg/dL, HDL bajo de 32 mg/dL y triglicéridos de 245 mg/dL, configurando un perfil de muy alto riesgo cardiovascular.

La función renal muestra deterioro con creatinina elevada (1.6 mg/dL), urea elevada (52 mg/dL) y presencia de microalbuminuria (85 mg/24h), indicando nefropatía diabética incipiente. Las enzimas hepáticas están elevadas, sugiriendo esteatosis hepática.

La evaluación visual muestra reducción significativa de la agudeza visual bilateral (20/40), con fondo de ojo que evidencia retinopatía hipertensiva grado II y signos de retinopatía diabética. Esto representa un RIESGO CRÍTICO para la seguridad en la conducción de vehículos. Es IMPERATIVO realizar evaluación oftalmológica urgente y considerar RESTRICCIÓN INMEDIATA de conducción hasta corrección adecuada y estabilización de las complicaciones oculares.

La audiometría revela pérdida auditiva moderada bilateral, lo que puede afectar la percepción de señales de alerta y comunicación en el ambiente laboral. Se requiere evaluación por especialista en otorrinolaringología.

El electrocardiograma muestra hipertrofia ventricular izquierda severa con alteraciones de repolarización, indicando daño cardíaco establecido. La radiografía de tórax confirma cardiomegalia. La espirometría evidencia patrón obstructivo moderado, compatible con EPOC en contexto de tabaquismo crónico.

El examen físico revela múltiples complicaciones: edema significativo en miembros inferiores, hepatomegalia, neuropatía periférica con disminución de sensibilidad en pies, y presencia de úlcera en pie derecho (pie diabético incipiente).

ACCIONES INMEDIATAS REQUERIDAS:
- Derivación URGENTE a médico internista/cardiólogo para manejo integral
- Inicio inmediato de tratamiento antihipertensivo optimizado
- Ajuste urgente de tratamiento antidiabético (considerar insulinización)
- Manejo agresivo de dislipidemia
- Evaluación oftalmológica URGENTE - RESTRICCIÓN INMEDIATA DE CONDUCCIÓN
- Evaluación por otorrinolaringología
- Evaluación por nefrología (nefropatía diabética)
- Evaluación de úlcera en pie por cirugía vascular
- Programa intensivo de cesación de tabaquismo
- Programa intensivo de reducción de peso
- Controles médicos SEMANALES hasta estabilización
- Exámenes complementarios: Ecocardiograma, Doppler de miembros inferiores, Ecografía abdominal

CONCLUSIÓN: NO APTO PARA EL TRABAJO HASTA CONTROL MÉDICO ESPECIALIZADO Y ESTABILIZACIÓN COMPLETA DE PARÁMETROS.
SE REQUIERE REEVALUACIÓN EN 30 DÍAS CON RESULTADOS DE ESPECIALISTAS Y EVIDENCIA DE CONTROL METABÓLICO.
RESTRICCIÓN ABSOLUTA DE CONDUCCIÓN DE VEHÍCULOS HASTA NUEVA EVALUACIÓN OFTALMOLÓGICA.'''
}
