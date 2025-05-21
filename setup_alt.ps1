# Complete-Setup-Spaceship.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.
# Idempotente: puedes ejecutarlo varias veces y siempre aplicará el mismo resultado.

# 0) Asegúrate de estar en PowerShell 7+ (Core)
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
Write-Host "[2/6] Asegurando módulos PSReadLine y posh-git…" -ForegroundColor Cyan
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

# 4) Genera o actualiza tema spaceship-custom.omp.json
Write-Host "[4/6] Generando tema Spaceship Custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if (-not (Test-Path $themeDir)) {
    New-Item -Path $themeDir -ItemType Directory | Out-Null
}

# Descarga la versión base de Spaceship
$baseUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/spaceship.omp.json'
$baseJson = Join-Path $themeDir 'spaceship.omp.json'
Invoke-WebRequest -Uri $baseUrl -OutFile $baseJson -UseBasicParsing -ErrorAction Stop

# Personaliza rutas y separadores
$customJson = Join-Path $themeDir 'spaceship-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
    switch ($seg.type) {
        'path' {
            # Rutas en cyan brillante y subrayadas, con separador » y diamante
            $seg.style = 'Foreground=BrightCyan;Underline'
            $seg.properties.Separator = ' » '
            $seg.leading_diamond_symbol = ''
            $seg.properties.Prefix = ''
        }
        'git_branch' {
            # Cambia el icono de rama a 
            $seg.properties.Icons.Branch = ''
        }
    }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "✔ Tema grabado en: $customJson" -ForegroundColor Green

# 5) Sobrescribe el perfil de PowerShell 7 (CurrentUserCurrentHost)
Write-Host "[5/6] Actualizando perfil de pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN pwsh Spaceship Setup ###
# PSReadLine (resaltado + autosuggestions)
if (-not (Get-Module -Name PSReadLine)) { Import-Module PSReadLine }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    String           = 'Gray'
    Comment          = 'DarkGray'
    Keyword          = 'Blue'
    Command          = 'Green'
    Parameter        = 'DarkCyan'
    Operator         = 'White'
    Variable         = 'Magenta'
    InlinePrediction = 'DarkGray'
}

# posh-git
if (-not (Get-Module -Name posh-git)) { Import-Module posh-git }

# Oh-My-Posh con Spaceship Custom
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh `
      --config="$HOME\Documents\PowerShell\Themes\spaceship-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "oh-my-posh no encontrado. Ejecuta: winget install JanDeDobbeleer.OhMyPosh"
}
### END pwsh Spaceship Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "✔ Perfil pwsh sobrescrito en: $profilePath" -ForegroundColor Green

# 6) Ajusta Windows Terminal: Fira Code Retina, ligaduras, padding y esquema OneHalfDark
Write-Host "[6/6] Configurando Windows Terminal…" -ForegroundColor Cyan
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtFile)) {
    $wtFile = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtFile) {
    $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

    # Define esquema OneHalfDark
    $scheme = @{
        name = 'OneHalfDark'
        foreground = '#dcd7ba'; background = '#282828'
        black = '#282828'; red = '#ea6962'
        green = '#a9b665'; yellow = '#e78a4e'
        blue = '#7daea3'; purple = '#d3869b'
        cyan = '#89b482'; white = '#dcd7ba'
        brightBlack = '#928374'; brightRed = '#ea6962'
        brightGreen = '#a9b665'; brightYellow = '#e78a4e'
        brightBlue = '#7daea3'; brightPurple = '#d3869b'
        brightCyan = '#89b482'; brightWhite = '#ffffff'
    }
    if (-not ($wt.schemes | Where-Object name -eq $scheme.name)) {
        $wt.schemes += $scheme
    }

    # Ajusta perfil pwsh
    foreach ($p in $wt.profiles.list) {
        if ($p.commandline -match 'pwsh.exe') {
            $p.fontFace = 'Fira Code Retina'
            $p.fontSize = 14
            $p.padding = '10,10,10,10'
            $p.fontFeatures = @('liga', 'calt', 'clig')
            $p.colorScheme = 'OneHalfDark'
            $wt.defaultProfile = $p.guid
        }
    }

    $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtFile -Encoding UTF8
    Write-Host "✔ Windows Terminal listo (OneHalfDark)." -ForegroundColor Green
}
else {
    Write-Warning "No se encontró settings.json de Windows Terminal."
}

Write-Host "`n✅ ¡Setup Spaceship completo! Cierra y abre pwsh y Windows Terminal." -ForegroundColor Magenta
