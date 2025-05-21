<#
.SYNOPSIS
  Configura PowerShell 7 + Windows Terminal con PSReadLine, posh-git y Oh-My-Posh
  y personaliza el tema para subrayar rutas válidas.

.USAGE
  Ejecuta en PowerShell 7 (no en ISE), con permisos de usuario:
    PS> .\setup-terminal.ps1
#>

# 1) Instala los módulos necesarios en CurrentUser
Write-Host "Instalando módulos PowerShell (PSReadLine, posh-git, oh-my-posh)..." -ForegroundColor Cyan
$mods = @('PSReadLine','posh-git','oh-my-posh')
foreach($m in $mods){
  if(-not (Get-Module -ListAvailable $m)) {
    Install-Module $m -Scope CurrentUser -Force -AllowClobber
  }
}

# 2) Asegura que exista tu perfil
if(-not (Test-Path -Path $PROFILE)) {
  New-Item -Type File -Path $PROFILE -Force | Out-Null
}

# 3) Añade/configura PSReadLine y posh-git + Oh-My-Posh en el perfil
$profileBlock = @"
### BEGIN Terminal Setup: PSReadLine + posh-git + oh-my-posh ###
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
  String            = 'DarkRed'
  Comment           = 'DarkGreen'
  Keyword           = 'Cyan'
  Command           = 'Green'
  Parameter         = 'Yellow'
  Operator          = 'White'
  Variable          = 'Magenta'
  InlinePrediction  = 'Gray'
}

Import-Module posh-git
Import-Module oh-my-posh

# Usa el tema personalizado
Set-PoshPrompt -Theme custom-terminal
### END Terminal Setup ###
"@

# Añádelo al final si no existe ya
if(-not (Select-String -Path $PROFILE -Pattern 'BEGIN Terminal Setup')) {
  Add-Content -Path $PROFILE -Value $profileBlock
  Write-Host "✔ Perfil actualizado: $PROFILE" -ForegroundColor Green
} else {
  Write-Host "– Perfil ya contiene configuración, saltando este paso." -ForegroundColor Yellow
}

# 4) Crea un tema custom (subraya rutas válidas)
Write-Host "Creando tema personalizado 'custom-terminal'…" -ForegroundColor Cyan
# Carpeta de temas de usuario
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if(-not (Test-Path $themeDir)) { New-Item -ItemType Directory -Path $themeDir | Out-Null }

# Ruta del tema base Paradox de Oh-My-Posh
$ompModule = (Get-Module -ListAvailable oh-my-posh)[0].ModuleBase
$baseTheme = Join-Path $ompModule 'themes\paradox.omp.json'
# Destino del custom
$destTheme = Join-Path $themeDir 'custom-terminal.omp.json'

# Carga JSON, modifica el segmento 'path'
$json = Get-Content $baseTheme -Raw | ConvertFrom-Json
foreach($seg in $json) {
  if($seg.type -eq 'path') {
    # subrayado + color DarkCyan en rutas válidas
    $seg.style = 'Underline;Foreground=DarkCyan'
  }
}
# Guarda el tema custom
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $destTheme -Encoding UTF8

Write-Host "✔ Tema guardado en: $destTheme" -ForegroundColor Green

Write-Host "`n✅ ¡Listo! Cierra y vuelve a abrir PowerShell 7 (o ejecuta `.` `$PROFILE`) para aplicar los cambios." -ForegroundColor Magenta
