$apiUrls = @{
    1 = "https://y4cqauzg3l.execute-api.us-east-2.amazonaws.com/prod/"
    2 = "https://a5zew8aykb.execute-api.us-east-2.amazonaws.com/prod/"
    3 = "https://j524pwy66a.execute-api.us-east-2.amazonaws.com/prod/"
    4 = "https://w0qf7jy257.execute-api.us-east-2.amazonaws.com/prod/"
    5 = "https://1iahfrgcg3.execute-api.us-east-2.amazonaws.com/prod/"
    6 = "https://xexiwkw4pd.execute-api.us-east-2.amazonaws.com/prod/"
}

foreach ($i in 1..6) {
    $bucket = "participant-$i-app-web-675544937470"
    $apiUrl = $apiUrls[$i]
    
    Write-Host "Procesando participant-$i con API URL: $apiUrl"
    
    # Leer el archivo original
    $content = Get-Content "frontend/index.html" -Raw -Encoding UTF8
    
    # Reemplazar el placeholder
    $content = $content -replace 'API_GATEWAY_URL_PLACEHOLDER', $apiUrl
    
    # Guardar en archivo temporal (UTF8 sin BOM)
    $tempFile = "temp-index-$i.html"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tempFile, $content, $utf8NoBom)
    
    # Subir a S3
    aws s3 cp $tempFile "s3://$bucket/index.html" --content-type "text/html" --profile pulsosalud-immersion
    
    # Limpiar archivo temporal
    Remove-Item $tempFile
    
    Write-Host "Completado participant-$i"
    Write-Host ""
}

Write-Host "Todos los archivos han sido actualizados"
