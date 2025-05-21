# Complete-Setup-Alt.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.

# 0) Comprobación de entorno
if ($PSVersionTable.PSEdition -ne 'Core') {
    Write-Error "Ejecuta este script en PowerShell 7 (pwsh), no en la consola clásica."
    exit 1
}

# 1) Eliminar perfil clásico de v5
$oldV5 = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path $oldV5) {
    Remove-Item $oldV5 -Force
    Write-Host "✔ Perfil PS v5 eliminado: $oldV5" -ForegroundColor Green
}

# 2) Instalar módulos PSReadLine y posh-git
Write-Host "[2/6] Instalando PSReadLine y posh-git…" -ForegroundColor Cyan
foreach ($m in 'PSReadLine','posh-git') {
    if (-not (Get-Module -ListAvailable $m)) {
        Install-Module $m -Scope CurrentUser -Force -AllowClobber
    }
}

# 3) Instalar Oh-My-Posh (ejecutable)
Write-Host "[3/6] Comprobando oh-my-posh…" -ForegroundColor Cyan
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "  → Instalando Oh-My-Posh con winget…" -ForegroundColor Yellow
    winget install JanDeDobbeleer.OhMyPosh -s winget --silent
}

# 4) Crear tema spaceship-custom.omp.json
Write-Host "[4/6] Generando tema spaceship-custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
New-Item -Path $themeDir -ItemType Directory -Force | Out-Null

# Descarga base spaceship
$baseUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/spaceship.omp.json'
$baseJson   = Join-Path $themeDir 'spaceship.omp.json'
Invoke-WebRequest -Uri $baseUrl -OutFile $baseJson -UseBasicParsing

# Modifica ruta y separadores
$customJson = Join-Path $themeDir 'spaceship-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
    if ($seg.type -eq 'path') {
        $seg.style                   = 'Foreground=BrightCyan;Underline'
        $seg.properties.Separator    = ' » '
        $seg.leading_diamond_symbol  = ''
    }
    if ($seg.type -eq 'git_branch') {
        $seg.properties.Icons.Branch = ''
    }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "  ✔ Tema creado: $customJson" -ForegroundColor Green

# 5) Sobrescribir perfil pwsh
Write-Host "[5/6] Escribiendo perfil pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN pwsh Alt Setup ###

# PSReadLine colores suaves
if (-not (Get-Module PSReadLine)) { Import-Module PSReadLine }
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
if (-not (Get-Module posh-git)) { Import-Module posh-git }

# Oh-My-Posh con spaceship-custom
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh `
      --config="$HOME\Documents\PowerShell\Themes\spaceship-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "Instala oh-my-posh: winget install JanDeDobbeleer.OhMyPosh"
}

### END pwsh Alt Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "  ✔ Perfil pwsh sobrescrito: $profilePath" -ForegroundColor Green

# 6) Configurar Windows Terminal
Write-Host "[6/6] Ajustando Windows Terminal…" -ForegroundColor Cyan
# Ubicación settings.json Store, con fallback Roaming
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtPath)) {
    $wtPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtPath) {
    $wt = Get-Content $wtPath -Raw | ConvertFrom-Json

    # Esquema OneHalfDark
    $scheme = @{
        name        = 'OneHalfDark'
        foreground  = '#dcd7ba'; background = '#282828'
        black       = '#282828'; red       = '#ea6962'
        green       = '#a9b665'; yellow    = '#e78a4e'
        blue        = '#7daea3'; purple    = '#d3869b'
        cyan        = '#89b482'; white     = '#dcd7ba'
        brightBlack = '#928374'; brightRed  = '#ea6962'
        brightGreen = '#a9b665'; brightYellow='#e78a4e'
        brightBlue  = '#7daea3'; brightPurple='#d3869b'
        brightCyan  = '#89b482'; brightWhite ='#ffffff'
    }
    if (-not ($wt.schemes | Where-Object name -eq $scheme.name)) {
        $wt.schemes += $scheme
    }

    # Ajusta perfil pwsh
    foreach ($p in $wt.profiles.list) {
        if ($p.commandline -match 'pwsh.exe') {
            $p.fontFace     = 'Fira Code Retina'
            $p.fontSize     = 14
            $p.padding      = '10,10,10,10'
            $p.fontFeatures = @('liga','calt','clig')
            $p.colorScheme  = 'OneHalfDark'
            $wt.defaultProfile = $p.guid
        }
    }

    $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtPath -Encoding UTF8
    Write-Host "  ✔ Windows Terminal configurado (OneHalfDark, Fira Code Retina)." -ForegroundColor Green
} else {
    Write-Warning "No encontré settings.json de Windows Terminal."
}

Write-Host "`n✅ Setup Alt completo. Cierra y abre pwsh y Windows Terminal nuevamente." -ForegroundColor Magenta
