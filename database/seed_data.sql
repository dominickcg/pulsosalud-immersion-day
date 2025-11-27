-- ========================================
-- Datos de seed para Medical Reports Automation
-- Datos de ejemplo para testing y demo
-- ========================================

-- ========================================
-- Contratistas de ejemplo
-- ========================================

INSERT INTO contratistas (nombre, email, telefono, direccion) VALUES
('Constructora ABC S.A.C.', 'rrhh@constructoraabc.com', '+51 1 234-5678', 'Av. Industrial 123, Lima'),
('Ingeniería XYZ Ltda.', 'recursos.humanos@ingenieriaxyz.com', '+51 1 345-6789', 'Jr. Los Constructores 456, Lima'),
('Obras Civiles del Sur', 'personal@obrasciviles.com', '+51 54 456-7890', 'Calle Arequipa 789, Arequipa'),
('Construcciones Modernas SAC', 'talento@construccionesmodernas.com', '+51 1 567-8901', 'Av. República 321, Lima'),
('Proyectos Industriales Perú', 'rrhh@proyectosindustriales.pe', '+51 1 678-9012', 'Av. Venezuela 654, Callao')
ON CONFLICT (email) DO NOTHING;

-- ========================================
-- Trabajadores de ejemplo
-- ========================================

INSERT INTO trabajadores (nombre, documento, fecha_nacimiento, genero, puesto) VALUES
('Juan Carlos Pérez García', '45678912', '1985-03-15', 'Masculino', 'Operador de maquinaria'),
('María Elena Rodríguez López', '56789123', '1990-07-22', 'Femenino', 'Supervisora de obra'),
('Carlos Alberto Sánchez Díaz', '67891234', '1982-11-08', 'Masculino', 'Electricista'),
('Ana Patricia Martínez Torres', '78912345', '1988-05-30', 'Femenino', 'Ingeniera de campo'),
('Luis Fernando González Ruiz', '89123456', '1995-09-12', 'Masculino', 'Soldador'),
('Rosa María Flores Vega', '91234567', '1987-02-18', 'Femenino', 'Técnica de seguridad'),
('Pedro José Ramírez Castro', '12345678', '1983-12-25', 'Masculino', 'Albañil'),
('Carmen Lucía Herrera Morales', '23456789', '1992-06-14', 'Femenino', 'Arquitecta'),
('Miguel Ángel Torres Jiménez', '34567891', '1986-08-03', 'Masculino', 'Técnico de mantenimiento'),
('Laura Isabel Vargas Mendoza', '45678923', '1991-04-27', 'Femenino', 'Coordinadora de proyectos')
ON CONFLICT (documento) DO NOTHING;

-- ========================================
-- Informes médicos de ejemplo
-- ========================================

-- Informe 1: Riesgo BAJO
INSERT INTO informes_medicos (
    trabajador_id, contratista_id, tipo_examen, fecha_examen,
    presion_arterial, peso, altura, imc, vision, audiometria, observaciones,
    origen, nivel_riesgo, justificacion_riesgo, procesado_por_ia
) VALUES (
    1, 1, 'Pre-empleo', '2025-01-15 09:30:00',
    '120/80', 72.5, 1.75, 23.7, '20/20', 'Normal',
    'Paciente en buen estado general. Todos los valores dentro de rangos normales. Apto para el puesto.',
    'LEGACY', 'BAJO', 
    'Presión arterial normal (120/80), IMC saludable (23.7), sin hallazgos patológicos.',
    TRUE
);

-- Informe 2: Riesgo MEDIO
INSERT INTO informes_medicos (
    trabajador_id, contratista_id, tipo_examen, fecha_examen,
    presion_arterial, peso, altura, imc, vision, audiometria, observaciones,
    origen, nivel_riesgo, justificacion_riesgo, procesado_por_ia
) VALUES (
    2, 2, 'Periódico', '2025-01-16 10:00:00',
    '135/88', 82.0, 1.68, 29.1, '20/25', 'Normal',
    'Paciente con valores límite de presión arterial. Sobrepeso leve. Recomendar control periódico y cambios en estilo de vida.',
    'LEGACY', 'MEDIO',
    'Presión arterial en rango límite (135/88), sobrepeso (IMC 29.1). Requiere seguimiento.',
    TRUE
);

-- Informe 3: Riesgo ALTO
INSERT INTO informes_medicos (
    trabajador_id, contratista_id, tipo_examen, fecha_examen,
    presion_arterial, peso, altura, imc, vision, audiometria, observaciones,
    origen, nivel_riesgo, justificacion_riesgo, procesado_por_ia
) VALUES (
    3, 1, 'Periódico', '2025-01-17 11:30:00',
    '165/105', 105.5, 1.75, 34.4, '20/30', 'Leve pérdida en frecuencias altas',
    'Paciente presenta hipertensión arterial severa. Obesidad grado II. Requiere evaluación cardiológica urgente y control médico estricto.',
    'LEGACY', 'ALTO',
    'Hipertensión severa (165/105), obesidad grado II (IMC 34.4). Riesgo cardiovascular alto.',
    TRUE
);

-- Informe 4: Pendiente de procesar
INSERT INTO informes_medicos (
    trabajador_id, contratista_id, tipo_examen, fecha_examen,
    presion_arterial, peso, altura, imc, vision, audiometria, observaciones,
    origen, procesado_por_ia
) VALUES (
    4, 3, 'Pre-empleo', '2025-01-18 14:00:00',
    '118/75', 68.0, 1.70, 23.5, '20/20', 'Normal',
    'Examen sin hallazgos patológicos. Paciente saludable.',
    'LEGACY', FALSE
);

-- Informe 5: Externo pendiente
INSERT INTO informes_medicos (
    trabajador_id, contratista_id, tipo_examen, fecha_examen,
    presion_arterial, peso, altura, imc, vision, audiometria, observaciones,
    origen, procesado_por_ia
) VALUES (
    5, 2, 'Reintegro laboral', '2025-01-19 15:30:00',
    '125/82', 78.0, 1.80, 24.1, '20/20', 'Normal',
    'Paciente recuperado de lesión. Apto para reintegro.',
    'EXTERNO', FALSE
);

-- ========================================
-- Resultados de laboratorio de ejemplo
-- ========================================

-- Laboratorio para Informe 1 (BAJO)
INSERT INTO laboratorio_resultados (
    informe_id, hemoglobina, hematocrito, globulos_blancos, plaquetas,
    colesterol_total, colesterol_hdl, colesterol_ldl, trigliceridos,
    glucosa_basal, creatinina, urea, acido_urico,
    tgo, tgp, bilirrubina_total
) VALUES (
    1, 15.2, 45.5, 7500, 250000,
    180, 55, 110, 120,
    85, 1.0, 28, 5.5,
    25, 30, 0.8
);

-- Laboratorio para Informe 2 (MEDIO)
INSERT INTO laboratorio_resultados (
    informe_id, hemoglobina, hematocrito, globulos_blancos, plaquetas,
    colesterol_total, colesterol_hdl, colesterol_ldl, trigliceridos,
    glucosa_basal, creatinina, urea, acido_urico,
    tgo, tgp, bilirrubina_total
) VALUES (
    2, 14.8, 44.2, 8200, 280000,
    220, 42, 145, 175,
    105, 1.1, 32, 6.8,
    32, 38, 0.9
);

-- Laboratorio para Informe 3 (ALTO)
INSERT INTO laboratorio_resultados (
    informe_id, hemoglobina, hematocrito, globulos_blancos, plaquetas,
    colesterol_total, colesterol_hdl, colesterol_ldl, trigliceridos,
    glucosa_basal, creatinina, urea, acido_urico,
    tgo, tgp, bilirrubina_total
) VALUES (
    3, 16.5, 48.8, 9500, 320000,
    265, 38, 175, 245,
    135, 1.2, 38, 7.5,
    42, 48, 1.1
);

-- ========================================
-- Historial de emails de ejemplo
-- ========================================

INSERT INTO historial_emails (informe_id, destinatario, asunto, cuerpo, estado) VALUES
(1, 'rrhh@constructoraabc.com', 
 'Informe Médico - Juan Carlos Pérez García - RIESGO BAJO',
 'Estimado equipo de RRHH,\n\nAdjunto encontrará el informe médico ocupacional del trabajador Juan Carlos Pérez García.\n\nNivel de Riesgo: BAJO\n\nEl trabajador se encuentra en condiciones óptimas para desempeñar sus funciones.\n\nSaludos cordiales.',
 'ENVIADO'),

(2, 'recursos.humanos@ingenieriaxyz.com',
 'Informe Médico - María Elena Rodríguez López - RIESGO MEDIO',
 'Estimado equipo de RRHH,\n\nAdjunto encontrará el informe médico ocupacional de la trabajadora María Elena Rodríguez López.\n\nNivel de Riesgo: MEDIO\n\nSe recomienda seguimiento médico periódico y cambios en estilo de vida.\n\nSaludos cordiales.',
 'ENVIADO'),

(3, 'rrhh@constructoraabc.com',
 'URGENTE - Informe Médico - Carlos Alberto Sánchez Díaz - RIESGO ALTO',
 'Estimado equipo de RRHH,\n\nAdjunto encontrará el informe médico ocupacional del trabajador Carlos Alberto Sánchez Díaz.\n\nNivel de Riesgo: ALTO\n\n⚠️ ATENCIÓN: El trabajador presenta hipertensión severa y requiere evaluación cardiológica urgente. Se recomienda suspender actividades de alto esfuerzo físico hasta nueva evaluación médica.\n\nSaludos cordiales.',
 'ENVIADO');

-- ========================================
-- Consultas útiles para verificar datos
-- ========================================

-- Ver todos los informes con información completa
-- SELECT * FROM informes_completos ORDER BY fecha_examen DESC;

-- Ver informes pendientes de procesar
-- SELECT * FROM informes_pendientes_ia;

-- Ver informes de alto riesgo
-- SELECT * FROM informes_alto_riesgo;

-- Ver estadísticas de riesgo
-- SELECT * FROM estadisticas_riesgo;

-- Ver conteo por origen
-- SELECT origen, COUNT(*) as total FROM informes_medicos GROUP BY origen;

-- Ver conteo por nivel de riesgo
-- SELECT nivel_riesgo, COUNT(*) as total FROM informes_medicos WHERE nivel_riesgo IS NOT NULL GROUP BY nivel_riesgo;

-- ========================================
-- Fin de datos de seed
-- ========================================
