# Complete-Setup-Solarized.ps1
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
foreach ($mod in 'PSReadLine','posh-git') {
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

# 4) Genera tema solarized-dark-custom.omp.json
Write-Host "[4/6] Generando tema solarized-dark-custom…" -ForegroundColor Cyan
$themeDir = Join-Path $HOME 'Documents\PowerShell\Themes'
if (-not (Test-Path $themeDir)) { New-Item -Path $themeDir -ItemType Directory | Out-Null }

# Descarga el preset base Solarized Dark
$baseUrl  = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/solarized-dark.omp.json'
$baseJson = Join-Path $themeDir 'solarized-dark.omp.json'
Invoke-WebRequest -Uri $baseUrl -OutFile $baseJson -UseBasicParsing

# Personaliza
$customJson = Join-Path $themeDir 'solarized-dark-custom.omp.json'
$j = Get-Content $baseJson -Raw | ConvertFrom-Json
foreach ($seg in $j) {
    switch ($seg.type) {
        'path' {
            # Icono de carpeta, separador › y subrayado amarillo
            $seg.properties.Prefix    = ' '
            $seg.properties.Separator = ' › '
            $seg.style                = 'Foreground=LightYellow;Underline'
        }
        'git_branch' {
            # Rama git en naranja suave
            $seg.style = 'Foreground=DarkSalmon'
        }
    }
}
$j | ConvertTo-Json -Depth 10 | Set-Content -Path $customJson -Encoding UTF8
Write-Host "  ✔ Tema creado: $customJson" -ForegroundColor Green

# 5) Sobrescribe perfil de PowerShell 7 (CurrentUserCurrentHost)
Write-Host "[5/6] Configurando perfil de pwsh…" -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
@'
### BEGIN Terminal Setup ###
# PSReadLine (resaltado + autosuggestions)
if (-not (Get-Module PSReadLine)) { Import-Module PSReadLine }
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

# posh-git
if (-not (Get-Module posh-git)) { Import-Module posh-git }

# Oh-My-Posh (tema solarized-dark-custom)
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    & $omp.Source init pwsh --config="$HOME\Documents\PowerShell\Themes\solarized-dark-custom.omp.json" |
      Invoke-Expression
} else {
    Write-Warning "Instala oh-my-posh con: winget install JanDeDobbeleer.OhMyPosh"
}
### END Terminal Setup ###
'@ | Set-Content -Path $profilePath -Encoding UTF8
Write-Host "  ✔ Perfil pwsh sobrescrito: $profilePath" -ForegroundColor Green

# 6) Ajusta Windows Terminal
Write-Host "[6/6] Ajustando Windows Terminal…" -ForegroundColor Cyan
# Detecta settings.json (Store o Roaming)
$wtFile = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtFile)) {
    $wtFile = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
}

if (Test-Path $wtFile) {
    $wt = Get-Content $wtFile -Raw | ConvertFrom-Json

    # Asegura esquema Solarized Dark
    $scheme = @{
        name        = 'Solarized Dark'
        foreground  = '#839496'; background = '#002b36'
        black       = '#073642'; red        = '#dc322f'
        green       = '#859900'; yellow     = '#b58900'
        blue        = '#268bd2'; purple     = '#d33682'
        cyan        = '#2aa198'; white      = '#eee8d5'
        brightBlack = '#002b36'; brightRed  = '#cb4b16'
        brightGreen = '#586e75'; brightYellow='#657b83'
        brightBlue  = '#839496'; brightPurple='#6c71c4'
        brightCyan  = '#93a1a1'; brightWhite ='#fdf6e3'
    }
    if (-not ($wt.schemes | Where-Object name -eq $scheme.name)) {
        $wt.schemes += $scheme
    }

    # Aplica al perfil pwsh
    foreach ($p in $wt.profiles.list) {
        if ($p.commandline -match 'pwsh.exe') {
            $p.fontFace     = 'Cascadia Code PL'
            $p.fontSize     = 13
            $p.padding      = '8,8,8,8'
            $p.fontFeatures = @('liga','calt','clig')
            $p.colorScheme  = 'Solarized Dark'
            $wt.defaultProfile = $p.guid
        }
    }

    $wt | ConvertTo-Json -Depth 5 | Set-Content -Path $wtFile -Encoding UTF8
    Write-Host "  ✔ Windows Terminal configurado (Solarized Dark)." -ForegroundColor Green
} else {
    Write-Warning "No se halló settings.json de Windows Terminal."
}

Write-Host "`n✅ Setup completo con tema Solarized Dark Custom. Cierra y abre tus terminales." -ForegroundColor Magenta
