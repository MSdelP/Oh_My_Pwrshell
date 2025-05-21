Configuración de PowerShell al estilo Zsh+Oh-My-Zsh

Este README explica cómo transformar tu Powershell 7 en Windows Terminal para que luzca y se comporte como Zsh con Oh-My-Zsh: sintaxis coloreada, Git integrado, autosuggestions y rutas subrayadas.

📦 Prerrequisitos

PowerShell 7: Descárgalo desde la Microsoft Store o desde GitHub.

Windows Terminal: Instálalo desde la Microsoft Store (o via winget) para pestañas, fondos translúcidos y personalización avanzada.

🔧 Instalación de módulos

Abre PowerShell 7 (pwsh) y ejecuta:

Install-Module PSReadLine -Scope CurrentUser -Force # Resaltado + autosuggestions
Install-Module posh-git -Scope CurrentUser -Force # Estado Git en el prompt

# oh-my-posh ahora se instala como ejecutable

winget install JanDeDobbeleer.OhMyPosh -s winget --silent

🛠️ Script de configuración automática

Hemos preparado un script Complete-Setup.ps1 que:

Borra el perfil clásico de PowerShell v5 (WindowsPowerShell).

Instala/actualiza PSReadLine, posh-git y Oh-My-Posh (ejecutable).

Descarga y genera un tema custom-terminal.omp.json con rutas subrayadas.

Sobrescribe tu perfil de PowerShell 7 (Documents\PowerShell\Microsoft.PowerShell_profile.ps1) para cargar solo PSReadLine, posh-git y Oh-My-Posh con powerlevel10k_classic.

Configura Windows Terminal: fuente Cascadia Code PL con ligaduras, padding 8,8,8,8, esquema de color Gruvbox Dark y establece pwsh como predeterminado.

Uso

Descarga o clona tu repositorio con Complete-Setup.ps1.

En pwsh (no en PS v5), ejecuta:

.\setup.ps1

Cierra todas las ventanas de pwsh y Windows Terminal y vuelve a abrir.

🎨 Temas alternativos, configuración manual y ajustes

PSReadLine: colores intensos (DarkRed, DarkGreen, Cyan, Green, Yellow, White, Magenta, Gray)

Oh-My-Posh: tema powerlevel10k_classic con sección de ruta subrayada en blanco sobre fondo oscuro

Windows Terminal:

Fuente: Cascadia Code PL

Ligaduras: ON

Padding: 8px en cada lado

Color scheme: Gruvbox Dark

Shell por defecto: PowerShell 7 (pwsh)
.\setup.ps1

PSReadLine: colores suaves (Gray, DarkGray, Blue…)

Oh-My-Posh: tema spaceship modificado para subrayar rutas en cyan y usar » como separador

Windows Terminal:

Fuente: Fira Code Retina (asegúrate de instalarla)

Ligaduras: ON

Padding: 10px en cada lado

Color scheme: OneHalfDark
.\setup_alt.ps1

PSReadLine: colores suaves (DarkYellow, DarkGray, Cyan, Green, Blue, White, Magenta, DarkGray)

Oh-My-Posh: tema Solarized Dark Custom con icono  en el path, separador › y rutas subrayadas en LightYellow

Windows Terminal:

Fuente: Cascadia Code PL

Ligaduras: ON

Padding: 8px en cada lado

Color scheme: Solarized Dark

Shell por defecto: PowerShell 7 (pwsh)
.\setup_solar.ps1

Para cambiar de tema basta con ejecutar cualquier script de nuevo

Si prefieres hacerlo paso a paso:

Crear carpeta de temas:

$themeDir = "$HOME\Documents\PowerShell\Themes"
if(-not (Test-Path $themeDir)) { New-Item -Path $themeDir -ItemType Directory }

Descargar y personalizar paradox.omp.json:

Invoke-WebRequest \
 -Uri 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json' \
 -OutFile "$themeDir\paradox.omp.json" -UseBasicParsing
$j = Get-Content "$themeDir\paradox.omp.json" -Raw | ConvertFrom-Json
$j | ForEach-Object {
if($_.type -eq 'path') {
    $_.style = 'Background=DarkSlateGray;Foreground=White;Underline'
    $_.properties.Separator = '  '
    $_.leading_diamond_symbol = ''
  }
}
$j | ConvertTo-Json -Depth 10 | Set-Content "$themeDir\custom-terminal.omp.json"

Editar tu perfil en pwsh:

notepad $PROFILE.CurrentUserCurrentHost

Pega solo el bloque:

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView -Colors @{
String='DarkRed';Comment='DarkGreen';Keyword='Cyan';Command='Green';Parameter='Yellow';
Operator='White';Variable='Magenta';InlinePrediction='Gray'
}
Import-Module posh-git

# OMP

$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
& $omp.Source init pwsh --theme powerlevel10k_classic |
Invoke-Expression

Guardar, recargar (. $PROFILE) y salir/entrar en pwsh.

🐞 Resolución de problemas

"'Khaki' is not a valid color value" o colores inválidos: usa solo los valores ConsoleColor:
Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White.

Errores con \ o init no reconocido: asegúrate de editar solo $PROFILE.CurrentUserCurrentHost en pwsh, no el de WindowsPowerShell.

oh-my-posh** no reconocido**: cierra y abre pwsh después de instalarlo via winget/scoop para actualizar $Env:Path.

Duplicación de PSReadLine en VSCode: usa esta comprobación para importar:

if(-not (Get-Module PSReadLine)) { Import-Module PSReadLine }

Windows Terminal no carga el esquema: revisa que tu settings.json esté en:

%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

o %LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json

¡Y eso es todo! Con estos pasos tendrás un terminal en Windows que rivaliza con cualquier configuración de Arch+Oh-My-Zsh.
