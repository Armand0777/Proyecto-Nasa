# Sube la versión web del juego a Vercel.
# Antes: en Godot, Proyecto > Exportar > Web > Exportar proyecto (queda en build\web).
# Uso, desde la carpeta del repositorio:
#   powershell -ExecutionPolicy Bypass -File despliegue\subir_a_vercel.ps1
# La primera vez la herramienta de Vercel pide iniciar sesión y crea el proyecto «mision-selene-ares»
# (el enlace queda como mision-selene-ares.vercel.app o parecido). Las veces siguientes actualiza ese mismo.

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$web = Join-Path $raiz "build\web"
# Se sube una copia con el nombre del juego: Vercel nombra el proyecto como la carpeta (no «web»).
$destino = Join-Path $raiz "build\mision-selene-ares"

if (-not (Test-Path (Join-Path $web "index.html"))) {
    Write-Host "No está la versión web en $web." -ForegroundColor Red
    Write-Host "Primero expórtala desde Godot: Proyecto > Exportar > Web > Exportar proyecto." -ForegroundColor Red
    exit 1
}

# Copia la exportación tal cual (borra lo viejo), sin tocar .vercel: ahí Vercel guarda a qué proyecto va.
robocopy $web $destino /MIR /XD .vercel /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Host "No se pudo copiar $web a $destino (robocopy terminó con $LASTEXITCODE)." -ForegroundColor Red
    exit 1
}
# Sin esto, Vercel podría intentar «armar» el proyecto: es una página ya lista, solo hay que servirla.
Copy-Item (Join-Path $PSScriptRoot "vercel.json") $destino -Force

npx vercel deploy --cwd $destino --prod --yes
exit $LASTEXITCODE
