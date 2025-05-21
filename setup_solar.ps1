# Complete-Setup-Solarized.ps1
# ──────────────────────────────────────────────────────────────────
# Ejecuta este script en PowerShell 7 (pwsh) con permisos de usuario.
# Idempotente: puedes volver a ejecutarlo tras reiniciar sin importar
# si ya lo habías corrido antes.

# 0) Asegúrate de estar en pwsh (edición Core)
if ($PSVersionTable.PSEdition -ne 'Core') {
    Write-Error "Este script solo funciona en PowerShell 7 (pwsh)."
    exit 1
}

# 1) Limpia el perfil clásico de PowerShell v5
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

# 4) Genera o actualiza tema Solarized Dark Custom
Write-Host "Generando tema Solarized Dark Custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if (-not (Test-Path $themeDir)) { New-Item -Path $themeDir -ItemType Directory | Out-Null }

# Base oficial (nota: guión bajo en el nombre)
$solarizedUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/solarized_dark.omp.json'
$baseJson = Join-Path $themeDir 'solarized_dark.omp.json'
Invoke-WebRequest -Uri $solarizedUrl -OutFile $baseJson -UseBasicParsing -ErrorAction Stop

# Personalizamos
$customJson = Join-Path $themeDir 'solarized-dark-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
    switch ($seg.type) {
        'path' {
            $seg.properties.Prefix = ' '            # icono de carpeta
            $seg.properties.Separator = ' › '
            $seg.style = 'Foreground=LightYellow;Underline'
        }
        'git_branch' {
            $seg.style = 'Foreground=DarkSalmon'
        }
    }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "✔ Tema grabado en $customJson" -ForegroundColor Green

# 5) Sobrescribe el perfil de PowerShell 7 (CurrentUserCurrentHost)
Write-Host "Actualizando perfil de pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN pwsh Solarized Setup ###
# 1) PSReadLine
if (-not (Get-Module -Name PSReadLine)) { Import-Module PSReadLine }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    String           = 'DarkYellow'
    Comment          = 'DarkGray'
    Keyword          = 'Cyan'
    Command          = 'Green'
    Parameter        = 'Blue'
    Operator         = 'White'
    Variable         = 'Magenta'
    InlinePrediction = 'DarkGray'
}

# 2) posh-git
if (-not (Get-Module -Name posh-git)) { Import-Module posh-git }

# 3) Oh-My-Posh: Solarized Dark Custom
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh `
      --config="$HOME\Documents\PowerShell\Themes\solarized-dark-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "oh-my-posh no encontrado en PATH."
}
### END pwsh Solarized Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "✔ Perfil pwsh escrito en $profilePath" -ForegroundColor Green

# 6) Ajusta Windows Terminal
Write-Host "Configurando Windows Terminal…" -ForegroundColor Cyan
# Ruta típica de Store, con fallback a Roaming
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtFile)) {
    $wtFile = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtFile) {
    $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

    # Añade scheme Solarized Dark
    $scheme = @{
        name = 'Solarized Dark'
        foreground = '#839496'; background = '#002b36'
        black = '#073642'; red = '#dc322f'
        green = '#859900'; yellow = '#b58900'
        blue = '#268bd2'; purple = '#d33682'
        cyan = '#2aa198'; white = '#eee8d5'
        brightBlack = '#002b36'; brightRed = '#cb4b16'
        brightGreen = '#586e75'; brightYellow = '#657b83'
        brightBlue = '#839496'; brightPurple = '#6c71c4'
        brightCyan = '#93a1a1'; brightWhite = '#fdf6e3'
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
            $p.colorScheme = 'Solarized Dark'
            $wt.defaultProfile = $p.guid
        }
    }

    $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtFile -Encoding UTF8
    Write-Host "✔ Windows Terminal listo (Solarized Dark)." -ForegroundColor Green
}
else {
    Write-Warning "No se ha encontrado settings.json de Windows Terminal."
}

Write-Host "`n✅ ¡Setup Solarized completo! Cierra y abre de nuevo pwsh y Windows Terminal." -ForegroundColor Magenta
