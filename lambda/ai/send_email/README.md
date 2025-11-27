# Lambda: Send Email

## Descripción
Lambda que envía emails personalizados según nivel de riesgo usando Amazon Nova Pro y SES.

## Funcionalidad
- Genera emails con tono adaptado al nivel de riesgo (ALTO: urgente, MEDIO: profesional, BAJO: tranquilizador)
- Envía emails usando Amazon SES
- Registra envíos en Aurora (historial_emails)

## Entrada
```json
{} // Procesa todos los pendientes
{"informe_id": 123} // Procesa uno específico
```

## Modelo de IA
- **Model ID:** amazon.nova-pro-v1:0
- **Temperature:** 0.7 (más creativo)
- **Max Tokens:** 800

## Variables de Entorno
- `VERIFIED_EMAIL`: Email verificado en SES
- `DB_SECRET_ARN`, `DB_CLUSTER_ARN`, `DATABASE_NAME`

## Permisos IAM
- `ses:SendEmail`, `ses:SendRawEmail`
- `bedrock:InvokeModel`
- `rds-data:ExecuteStatement`
- `secretsmanager:GetSecretValue`

## Invocación
```bash
aws lambda invoke --function-name demo-send-email --payload '{}' response.json
```

## Base de Datos
```sql
UPDATE informes_medicos SET email_enviado = true WHERE id = :id;
INSERT INTO historial_emails (informe_id, destinatario, cuerpo, estado) VALUES (...);
```
