# Complete-Setup-Paradox.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.
# Idempotente: puedes volver a ejecutarlo tras reiniciar sin importar
# si ya lo habías corrido antes.

# 0) Asegúrate de estar en pwsh (edición Core)
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

# 2) Asegura PSReadLine y posh-git instalados
foreach ($mod in 'PSReadLine', 'posh-git') {
  if (-not (Get-Module -ListAvailable $mod)) {
    Write-Host "Instalando módulo $mod…" -ForegroundColor Cyan
    Install-Module $mod -Scope CurrentUser -Force -AllowClobber
  }
}

# 3) Asegura Oh-My-Posh instalado (ejecutable)
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
  Write-Host "Instalando Oh-My-Posh (winget) …" -ForegroundColor Cyan
  winget install JanDeDobbeleer.OhMyPosh -s winget --silent
}

# 4) Genera o actualiza tema Paradox Custom
Write-Host "Generando tema Paradox Custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if (-not (Test-Path $themeDir)) { New-Item -Path $themeDir -ItemType Directory | Out-Null }

$paradoxUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json'
$baseJson = Join-Path $themeDir 'paradox.omp.json'
Invoke-WebRequest -Uri $paradoxUrl -OutFile $baseJson -UseBasicParsing -ErrorAction Stop

$customJson = Join-Path $themeDir 'paradox-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
  if ($seg.type -eq 'path') {
    # ruta con fondo oscuro, texto blanco, subrayado
    $seg.style = 'Background=DarkSlateGray;Foreground=White;Underline'
    $seg.properties.Separator = '  '
    $seg.leading_diamond_symbol = ''
  }
  elseif ($seg.type -eq 'git_branch') {
    # icono de rama personalizado
    $seg.properties.Icons.Branch = ''
  }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "✔ Tema grabado en: $customJson" -ForegroundColor Green

# 5) Sobrescribe el perfil de PowerShell 7 (CurrentUserCurrentHost)
Write-Host "Actualizando perfil de pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN pwsh Paradox Setup ###
# 1) PSReadLine (resaltado y autosuggestions)
if (-not (Get-Module PSReadLine)) { Import-Module PSReadLine }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    String           = 'DarkRed'
    Comment          = 'DarkGreen'
    Keyword          = 'Cyan'
    Command          = 'Green'
    Parameter        = 'Yellow'
    Operator         = 'White'
    Variable         = 'Magenta'
    InlinePrediction = 'Gray'
}

# 2) posh-git
if (-not (Get-Module posh-git)) { Import-Module posh-git }

# 3) Oh-My-Posh: Paradox Custom
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh `
      --config="$HOME\Documents\PowerShell\Themes\paradox-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "oh-my-posh no encontrado en PATH. Ejecuta: winget install JanDeDobbeleer.OhMyPosh"
}
### END pwsh Paradox Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "✔ Perfil pwsh sobrescrito en: $profilePath" -ForegroundColor Green

# 6) Ajusta Windows Terminal
Write-Host "Configurando Windows Terminal…" -ForegroundColor Cyan
# Detecta settings.json (Store o Roaming)
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtFile)) {
  $wtFile = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtFile) {
  $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

  # Añade esquema Gruvbox Dark
  $scheme = @{
    name = 'Gruvbox Dark'
    foreground = '#EBDBB2'; background = '#282828'
    black = '#282828'; red = '#CC241D'
    green = '#98971A'; yellow = '#D79921'
    blue = '#458588'; purple = '#B16286'
    cyan = '#689D6A'; white = '#A89984'
    brightBlack = '#928374'; brightRed = '#FB4934'
    brightGreen = '#B8BB26'; brightYellow = '#FABD2F'
    brightBlue = '#83A598'; brightPurple = '#D3869B'
    brightCyan = '#8EC07C'; brightWhite = '#EBDBB2'
  }
  if (-not ($wt.schemes | Where-Object name -eq $scheme.name)) {
    $wt.schemes += $scheme
  }

  foreach ($p in $wt.profiles.list) {
    if ($p.commandline -match 'pwsh.exe') {
      $p.fontFace = 'Cascadia Code PL'
      $p.fontSize = 13
      $p.padding = '8,8,8,8'
      $p.fontFeatures = @('liga', 'calt', 'clig')
      $p.colorScheme = 'Gruvbox Dark'
      $wt.defaultProfile = $p.guid
    }
  }

  $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtFile -Encoding UTF8
  Write-Host "✔ Windows Terminal listo con Gruvbox Dark." -ForegroundColor Green
}
else {
  Write-Warning "No se encontró settings.json de Windows Terminal."
}

Write-Host "`n✅ Setup Paradox completo. Cierra y abre pwsh y Windows Terminal." -ForegroundColor Magenta
