# Paso 6 - Cliente HTTP (PowerShell)
# Ejecuta las 9 peticiones del taller contra la API y verifica cada resultado esperado.
#
# Uso:
#   1. Levanta la API y reinicia sus datos (estan en memoria):
#        python -m uvicorn app.main:app
#   2. En otra terminal:
#        powershell -ExecutionPolicy Bypass -File cliente-http\probar_api.ps1
#
# Variable de la URL base (cambiala si corres en otro puerto, p.ej. 8001).

$baseUrl = "http://127.0.0.1:8001"
$inscripcionId = $null
$fallos = 0

function Verificar($nombre, $esperado, $obtenido) {
    if ($esperado -eq $obtenido) {
        Write-Host ("  OK  {0}  ->  {1}" -f $nombre, $obtenido) -ForegroundColor Green
    } else {
        Write-Host ("  FALLO  {0}  ->  esperado {1}, obtenido {2}" -f $nombre, $esperado, $obtenido) -ForegroundColor Red
        $script:fallos++
    }
}

# Devuelve un objeto con .Code (status) y .Body (json parseado).
# Captura los 4xx/5xx con try/catch para que funcione en Windows PowerShell 5.1 y en 7+.
function Pedir($metodo, $ruta, $cuerpo) {
    $uri = "$baseUrl$ruta"
    try {
        if ($cuerpo) {
            $r = Invoke-WebRequest -Uri $uri -Method $metodo -ContentType "application/json" -Body ($cuerpo | ConvertTo-Json) -UseBasicParsing
        } else {
            $r = Invoke-WebRequest -Uri $uri -Method $metodo -UseBasicParsing
        }
        $code = [int]$r.StatusCode
        $content = $r.Content
    } catch {
        $resp = $_.Exception.Response
        if ($null -eq $resp) { throw }
        $code = [int]$resp.StatusCode
        # PowerShell 5.1 ya consumio el cuerpo del error: esta en ErrorDetails.Message.
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $content = $_.ErrorDetails.Message
        } else {
            $stream = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $content = $stream.ReadToEnd()
            $stream.Close()
        }
    }
    $body = $null
    if ($content) { try { $body = $content | ConvertFrom-Json } catch { $body = $content } }
    return [pscustomobject]@{ Code = $code; Body = $body }
}

Write-Host "`n== Secuencia de pruebas contra $baseUrl ==`n"

Write-Host "1. POST inscribir e1 en IS2  (201)"
$r = Pedir POST "/inscripciones" @{ estudiante_id = "e1"; curso_codigo = "IS2" }
Verificar "status" 201 $r.Code
Verificar "estado" "ACTIVA" $r.Body.estado
$inscripcionId = $r.Body.id

Write-Host "2. POST inscribir e1 en IS2 otra vez  (409 DUPLICADA)"
$r = Pedir POST "/inscripciones" @{ estudiante_id = "e1"; curso_codigo = "IS2" }
Verificar "status" 409 $r.Code
Verificar "detail" "DUPLICADA" $r.Body.detail

Write-Host "3. POST inscribir e4 en IS2  (409 PRERREQUISITOS_PENDIENTES)"
$r = Pedir POST "/inscripciones" @{ estudiante_id = "e4"; curso_codigo = "IS2" }
Verificar "status" 409 $r.Code
Verificar "detail" "PRERREQUISITOS_PENDIENTES" $r.Body.detail

Write-Host "4. POST inscribir e2 en IS2  (201)"
$r = Pedir POST "/inscripciones" @{ estudiante_id = "e2"; curso_codigo = "IS2" }
Verificar "status" 201 $r.Code
Verificar "estado" "ACTIVA" $r.Body.estado

Write-Host "5. POST inscribir e3 en IS2  (409 SIN_CUPO)"
$r = Pedir POST "/inscripciones" @{ estudiante_id = "e3"; curso_codigo = "IS2" }
Verificar "status" 409 $r.Code
Verificar "detail" "SIN_CUPO" $r.Body.detail

Write-Host "6. GET /inscripciones/$inscripcionId  (200)"
$r = Pedir GET "/inscripciones/$inscripcionId" $null
Verificar "status" 200 $r.Code
Verificar "id" $inscripcionId $r.Body.id

Write-Host "7. GET /estudiantes/e1/inscripciones  (200)"
$r = Pedir GET "/estudiantes/e1/inscripciones" $null
Verificar "status" 200 $r.Code

Write-Host "8. PATCH /inscripciones/$inscripcionId a CANCELADA  (200)"
$r = Pedir PATCH "/inscripciones/$inscripcionId" @{ estado = "CANCELADA" }
Verificar "status" 200 $r.Code
Verificar "estado" "CANCELADA" $r.Body.estado

Write-Host "9. GET /cursos  (200, IS2 con 1 cupo disponible)"
$r = Pedir GET "/cursos" $null
Verificar "status" 200 $r.Code
$is2 = $r.Body | Where-Object { $_.codigo -eq "IS2" }
Verificar "IS2 cupos_disponibles" 1 $is2.cupos_disponibles

Write-Host ""
if ($fallos -eq 0) {
    Write-Host "TODAS LAS PRUEBAS PASARON" -ForegroundColor Green
} else {
    Write-Host ("$fallos verificacion(es) fallaron") -ForegroundColor Red
}
