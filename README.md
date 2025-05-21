Configuración de PowerShell al estilo Zsh+Oh-My-Zsh

Este README explica cómo transformar tu PowerShell 7 en Windows Terminal para que luzca y se comporte como Zsh con Oh-My-Zsh: colores de sintaxis, Git integrado, autosuggestions y rutas subrayadas.

📦 Prerrequisitos

PowerShell 7: Descárgalo desde la Microsoft Store o desde el repositorio oficial en GitHub.

Windows Terminal: Instálalo también desde la Microsoft Store para gestionar pestañas, fondos translúcidos y personalizar fuentes y colores.

🔧 Instalación de módulos

Abre PowerShell 7 y ejecuta:
```
Install-Module PSReadLine -Scope CurrentUser -Force      # Sintaxis y autosuggestions
Install-Module posh-git -Scope CurrentUser -Force      # Indicadores de Git en el prompt
Install-Module oh-my-posh -Scope CurrentUser -Force      # Temas de prompt muy configurables
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

🚀 Uso y ajustes finales del script

📝 Resumen de pasos

Instalación de módulos:

PSReadLine (resaltado de sintaxis+autosuggestions)

posh-git (información de Git en el prompt)

oh-my-posh (diseño de prompt muy configurable)

Perfil ($PROFILE):

Carga todos los módulos

Configura colores de tokens y autosuggestions inline

Aplica el tema custom-terminal que creamos

Tema personalizado:

Copia el tema base paradox.omp.json

Busca el bloque "type": "path" y le añade Underline;Foreground=DarkCyan

Guarda como custom-terminal.omp.json en tu carpeta de temas

Activación:

Tras reiniciar PowerShell 7 (o ejecutar . $PROFILE), tendrás:

Colores de sintaxis y autosuggestions

Prompt multicolor con usuario, ruta, estado Git

Ruta válida subrayada en tu prompt

¡Disfruta de tu nuevo terminal al estilo Arch-Zsh en Windows!

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

¡Disfruta de tu terminal al nivel de cualquier setup de Arch Linux o Oh-My-Zsh en Windows!


