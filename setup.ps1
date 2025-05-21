# Complete-Setup.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.

# 0) Comprueba edición
if ($PSVersionTable.PSEdition -ne 'Core') {
  Write-Error "Ejecuta este script en PowerShell 7 (pwsh), no en la consola clásica."
  exit 1
}

# 1) Borra perfil de Windows PowerShell v5
$old = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path $old) {
  Remove-Item $old -Force
  Write-Host "✔ Perfil clásico eliminado: $old" -ForegroundColor Green
}

# 2) Instala PSReadLine y posh-git
Write-Host "[2/6] Instalando PSReadLine y posh-git…" -ForegroundColor Cyan
foreach ($mod in 'PSReadLine', 'posh-git') {
  if (-not (Get-Module -ListAvailable $mod)) {
    Install-Module $mod -Scope CurrentUser -Force -AllowClobber
  }
}

# 3) Instala Oh-My-Posh si hace falta
Write-Host "[3/6] Comprobando oh-my-posh…" -ForegroundColor Cyan
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
  Write-Host "  → Instalando Oh-My-Posh con winget…" -ForegroundColor Yellow
  winget install JanDeDobbeleer.OhMyPosh -s winget --silent
}

# 4) Genera tema custom-terminal.omp.json
Write-Host "[4/6] Generando tema custom-terminal…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
New-Item -Path $themeDir -ItemType Directory -Force | Out-Null

$rawUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json'
$base = Join-Path $themeDir 'paradox.omp.json'
Invoke-WebRequest -Uri $rawUrl -OutFile $base -UseBasicParsing

$custom = Join-Path $themeDir 'custom-terminal.omp.json'
$j = Get-Content $base -Raw | ConvertFrom-Json
foreach ($seg in $j) {
  if ($seg.type -eq 'path') {
    $seg.style = 'Background=DarkSlateGray;Foreground=White;Underline'
    $seg.properties.Separator = '  '
    $seg.leading_diamond_symbol = ''
  }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $custom -Encoding UTF8
Write-Host "  ✔ Tema creado: $custom" -ForegroundColor Green

# 5) Sobrescribe perfil de PowerShell 7 (CurrentUserAllHosts)
Write-Host "[5/6] Configurando perfil de pwsh…" -ForegroundColor Cyan
$newProfile = $PROFILE.CurrentUserAllHosts
@"
### BEGIN Terminal Setup ###
# PSReadLine (resaltado + autosuggestions)
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

# posh-git
if (-not (Get-Module posh-git)) { Import-Module posh-git }

# Oh-My-Posh (tema powerlevel10k_classic)
$omp = (Get-Command oh-my-posh).Source
& $omp init pwsh --config="$HOME\Documents\PowerShell\Themes\custom-terminal.omp.json" | Invoke-Expression
### END Terminal Setup ###
"@ | Set-Content -Path $newProfile -Encoding UTF8
Write-Host "  ✔ Perfil pwsh sobrescrito: $newProfile" -ForegroundColor Green

# 6) Ajusta Windows Terminal
Write-Host "[6/6] Ajustando Windows Terminal…" -ForegroundColor Cyan
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wtFile) {
  $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

  # Añade Gruvbox Dark si falta
  $scheme = @{
    name = 'Gruvbox Dark'
    foreground = '#EBDBB2'; background = '#282828'
    black = '#282828'; red = '#CC241D'; green = '#98971A'; yellow = '#D79921'
    blue = '#458588'; purple = '#B16286'; cyan = '#689D6A'; white = '#A89984'
    brightBlack = '#928374'; brightRed = '#FB4934'; brightGreen = '#B8BB26'
    brightYellow = '#FABD2F'; brightBlue = '#83A598'; brightPurple = '#D3869B'
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
  Write-Host "  ✔ Windows Terminal configurado." -ForegroundColor Green
}
else {
  Write-Warning "No se halló settings.json de Windows Terminal."
}

Write-Host "`n✅ Setup completo. Cierra y abre de nuevo tus sesiones de pwsh y Windows Terminal." -ForegroundColor Magenta
