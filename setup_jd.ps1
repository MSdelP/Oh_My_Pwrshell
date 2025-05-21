# Complete-Setup-JD.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.
# Idempotente: puedes ejecutarlo varias veces y siempre aplicará la misma configuración.

# 0) Asegúrate de estar en PowerShell 7 (Core)
if ($PSVersionTable.PSEdition -ne 'Core') {
  Write-Error "Este script solo funciona en PowerShell 7 (pwsh)."
  exit 1
}

# 1) Elimina el perfil clásico de PowerShell v5
$oldV5 = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path $oldV5) {
  Remove-Item $oldV5 -Force
  Write-Host "✔ Perfil clásico v5 eliminado: $oldV5" -ForegroundColor Green
}

# 2) Instala o actualiza PSReadLine y posh-git
Write-Host "[2/6] Instalando módulos PSReadLine y posh-git…" -ForegroundColor Cyan
foreach ($mod in 'PSReadLine', 'posh-git') {
  if (-not (Get-Module -ListAvailable $mod)) {
    Install-Module $mod -Scope CurrentUser -Force -AllowClobber
  }
}

# 3) Instala Oh-My-Posh (ejecutable) si falta
Write-Host "[3/6] Comprobando oh-my-posh…" -ForegroundColor Cyan
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
  Write-Host "  → Instalando Oh-My-Posh con winget…" -ForegroundColor Yellow
  winget install JanDeDobbeleer.OhMyPosh -s winget --silent
}

# 4) Genera o actualiza tema Jandedobbeleer Custom
Write-Host "[4/6] Generando tema JDb Custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if (-not (Test-Path $themeDir)) { New-Item -Path $themeDir -ItemType Directory | Out-Null }

# Descarga el preset base jandedobbeleer
$baseUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json'
$baseJson = Join-Path $themeDir 'jandedobbeleer.omp.json'
Invoke-WebRequest -Uri $baseUrl -OutFile $baseJson -UseBasicParsing -ErrorAction Stop

# Personaliza rutas y git_branch
$customJson = Join-Path $themeDir 'jdb-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
  switch ($seg.type) {
    'path' {
      # ruta en magenta sobre fondo gris, subrayado
      $seg.style = 'Background=DarkGray;Foreground=Magenta;Underline'
      $seg.properties.Separator = ' ⟩ '
      $seg.properties.Prefix = '📁 '
    }
    'git_branch' {
      # git branch en amarillo brillante
      $seg.style = 'Foreground=BrightYellow'
    }
  }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "✔ Tema grabado en: $customJson" -ForegroundColor Green

# 5) Sobrescribe el perfil de pwsh (CurrentUserCurrentHost)
Write-Host "[5/6] Actualizando perfil de pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN pwsh JDb Setup ###
# PSReadLine (colores vibrantes)
if (-not (Get-Module -Name PSReadLine)) { Import-Module PSReadLine }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    String           = 'BrightGreen'
    Comment          = 'DarkBlue'
    Keyword          = 'BrightMagenta'
    Command          = 'BrightCyan'
    Parameter        = 'Yellow'
    Operator         = 'White'
    Variable         = 'BrightWhite'
    InlinePrediction = 'DarkGray'
}

# posh-git
if (-not (Get-Module -Name posh-git)) { Import-Module posh-git }

# Oh-My-Posh con JDb Custom
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh `
      --config="$HOME\Documents\PowerShell\Themes\jdb-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "oh-my-posh no encontrado. Ejecuta: winget install JanDeDobbeleer.OhMyPosh"
}
### END pwsh JDb Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "✔ Perfil pwsh sobrescrito: $profilePath" -ForegroundColor Green

# 6) Configura Windows Terminal: fuente, padding y esquema Dracula
Write-Host "[6/6] Configurando Windows Terminal…" -ForegroundColor Cyan
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtFile)) {
  $wtFile = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtFile) {
  $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

  # Añade esquema Dracula
  $scheme = @{
    name = 'Dracula'
    foreground = '#f8f8f2'; background = '#282a36'
    black = '#21222c'; red = '#ff5555'
    green = '#50fa7b'; yellow = '#f1fa8c'
    blue = '#bd93f9'; purple = '#ff79c6'
    cyan = '#8be9fd'; white = '#f8f8f2'
    brightBlack = '#6272a4'; brightRed = '#ff6e6e'
    brightGreen = '#69ff94'; brightYellow = '#ffffa5'
    brightBlue = '#d6acff'; brightPurple = '#ff92df'
    brightCyan = '#a4ffff'; brightWhite = '#ffffff'
  }
  if (-not ($wt.schemes | Where-Object name -eq $scheme.name)) {
    $wt.schemes += $scheme
  }

  # Ajusta el perfil pwsh
  foreach ($p in $wt.profiles.list) {
    if ($p.commandline -match 'pwsh.exe') {
      $p.fontFace = 'Cascadia Code PL'
      $p.fontSize = 13
      $p.padding = '10,10,10,10'
      $p.fontFeatures = @('liga', 'calt', 'clig')
      $p.colorScheme = 'Dracula'
      $wt.defaultProfile = $p.guid
    }
  }

  $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtFile -Encoding UTF8
  Write-Host "✔ Windows Terminal listo (Dracula)." -ForegroundColor Green
}
else {
  Write-Warning "No se encontró settings.json de Windows Terminal."
}

Write-Host "`n✅ ¡Setup JDb (Dracula) completo! Cierra y abre de nuevo pwsh y Windows Terminal." -ForegroundColor Magenta
