Configuración de PowerShell al estilo Zsh+Oh-My-Zsh

Este README explica cómo transformar tu PowerShell 7 en Windows Terminal para que luzca y se comporte como Zsh con Oh-My-Zsh: colores de sintaxis, Git integrado, autosuggestions y rutas subrayadas.

📦 Prerrequisitos

PowerShell 7: Descárgalo desde la Microsoft Store o desde el repositorio oficial en GitHub.

Windows Terminal: Instálalo también desde la Microsoft Store para gestionar pestañas, fondos translúcidos y personalizar fuentes y colores.

🔧 Instalación de módulos

Abre PowerShell 7 y ejecuta:
```
Install-Module PSReadLine -Scope CurrentUser -Force      # Sintaxis y autosuggestions
tInstall-Module posh-git    -Scope CurrentUser -Force      # Indicadores de Git en el prompt
Install-Module oh-my-posh   -Scope CurrentUser -Force      # Temas de prompt muy configurables
```
🛠️ Configuración del perfil ($PROFILE)

Añade al final de tu perfil (notepad $PROFILE o code $PROFILE) el siguiente bloque:
```
### BEGIN Terminal Setup: PSReadLine + posh-git + oh-my-posh ###
Import-Module PSReadLine
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

Import-Module posh-git
Import-Module oh-my-posh
# Aplica nuestro tema personalizado
Set-PoshPrompt -Theme custom-terminal
### END Terminal Setup ###
```
Guarda el archivo y recarga tu perfil con:
```
. $PROFILE
```
🎨 Creación de un tema personalizado

Carpeta de temas de usuario:

$themeDir = "$HOME\Documents\PowerShell\Themes"
if(-not (Test-Path $themeDir)) { New-Item -ItemType Directory -Path $themeDir }

Copia y modifica el tema base (Paradox) de Oh-My-Posh:
```
$base = (Get-Module -ListAvailable oh-my-posh)[0].ModuleBase + '\themes\paradox.omp.json'
$dest = "$themeDir\custom-terminal.omp.json"
$json = Get-Content $base -Raw | ConvertFrom-Json
foreach($seg in $json) {
  if($seg.type -eq 'path') {
    $seg.style = 'Underline;Foreground=DarkCyan'
  }
}
$json | ConvertTo-Json -Depth 10 | Set-Content $dest -Encoding UTF8
```
Ahora el tema custom-terminal mostrará la ruta actual subrayada en color DarkCyan cuando exista en disco.

🚀 Uso y ajustes finales

Reinicia PowerShell 7 o vuelve a cargar tu perfil:
```
. $PROFILE
```
Explora otros temas con:
```
Get-PoshThemes
Set-PoshPrompt -Theme <NombreDelTema>
```
Personaliza más opciones de PSReadLine (líneas de separador, búsqueda en history, etc.) con Get-Help Set-PSReadLineOption.
