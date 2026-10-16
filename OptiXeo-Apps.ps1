<#
  OptiXeo - catálogo de programas para instalar en cualquier PC.
  Usa winget (viene con Windows 10/11): cada paquete se descarga de la web
  oficial de su fabricante y winget comprueba su SHA256 antes de instalarlo.
  Se carga con ". .\OptiXeo-Apps.ps1" desde la interfaz.
#>

$AppCatalog = @(
    @{ Group = 'Librerías';    Name = 'Visual C++ 2005 a 2026 (todas)'; Icon = 'vcredist'; Desc = 'Las 12 versiones oficiales de Microsoft, x86 y x64. Muchos juegos y programas las necesitan.'
       Ids = @('Microsoft.VCRedist.2005.x86', 'Microsoft.VCRedist.2005.x64', 'Microsoft.VCRedist.2008.x86', 'Microsoft.VCRedist.2008.x64',
               'Microsoft.VCRedist.2010.x86', 'Microsoft.VCRedist.2010.x64', 'Microsoft.VCRedist.2012.x86', 'Microsoft.VCRedist.2012.x64',
               'Microsoft.VCRedist.2013.x86', 'Microsoft.VCRedist.2013.x64', 'Microsoft.VCRedist.2015+.x86', 'Microsoft.VCRedist.2015+.x64') }
    @{ Group = 'Librerías';    Name = 'DirectX 9 (runtime)'; Icon = 'directx'; Ids = @('Microsoft.DirectX');            Desc = 'Bibliotecas D3DX9/10/11, XAudio y XInput que piden los juegos antiguos.' }
    @{ Group = 'Librerías';    Name = 'XNA Framework 4.0'; Icon = 'xna';   Ids = @('Microsoft.XNARedist');          Desc = 'Última versión publicada (4.0 Refresh). La necesitan los juegos hechos con XNA.' }
    @{ Group = 'Multimedia';   Name = 'VLC media player'; Icon = 'vlc';    Ids = @('VideoLAN.VLC');                 Desc = 'Reproduce cualquier vídeo o audio sin instalar códecs.' }
    @{ Group = 'Multimedia';   Name = 'IrfanView + plugins'; Icon = 'irfanview'; Ids = @('IrfanSkiljan.IrfanView', 'IrfanSkiljan.IrfanView.PlugIns'); Desc = 'Visor de imágenes ligero con todos los plugins oficiales.' }
    @{ Group = 'Multimedia';   Name = 'Spotify'; Icon = 'spotify';             Ids = @('Spotify.Spotify'); NoAdmin = $true; Desc = 'Versión de escritorio (.exe), no la de Microsoft Store.' }
    @{ Group = 'Multimedia';   Name = 'OBS Studio'; Icon = 'obs';          Ids = @('OBSProject.OBSStudio');         Desc = 'Grabación de pantalla y directos.' }
    @{ Group = 'Utilidades';   Name = '7-Zip'; Icon = '7zip';               Ids = @('7zip.7zip');                    Desc = 'Compresor libre: 7z, zip, rar, iso...' }
    @{ Group = 'Utilidades';   Name = 'WinRAR'; Icon = 'winrar';              Ids = @('RARLab.WinRAR');                Desc = 'Compresor RAR (en español).' }
    @{ Group = 'Desarrollo';   Name = 'Visual Studio Code'; Icon = 'vscode';  Ids = @('Microsoft.VisualStudioCode');   Desc = 'Editor de código de Microsoft.' }
    @{ Group = 'Desarrollo';   Name = 'Antigravity'; Icon = 'antigravity';         Ids = @('Google.Antigravity');           Desc = 'Centro de agentes de IA de Google.' }
    @{ Group = 'Desarrollo';   Name = 'Orca'; Icon = 'orca';                Ids = @('StablyAI.Orca');                Desc = 'Gestor de terminales y agentes (stablyai).' }
    @{ Group = 'Juegos';       Name = 'Steam'; Icon = 'steam';               Ids = @('Valve.Steam');                  Desc = 'Tienda y biblioteca de juegos de Valve.' }
    @{ Group = 'Juegos';       Name = 'Epic Games Launcher'; Icon = 'epic'; Ids = @('EpicGames.EpicGamesLauncher');  Desc = 'Tienda y biblioteca de Epic Games.' }
)

function Get-WingetPath {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $alias) { return $alias }
    $null
}

# IDs de winget instalados en este PC (una sola llamada, mucho más rápido que preguntar uno a uno).
function Get-InstalledWingetIds {
    $winget = Get-WingetPath
    if (-not $winget) { return $null }
    $tmp = Join-Path $env:TEMP "optixeo-winget-$PID.json"
    & $winget export -o $tmp --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
    if (-not (Test-Path $tmp)) { return @() }
    $json = Get-Content $tmp -Raw | ConvertFrom-Json
    Remove-Item $tmp -ErrorAction SilentlyContinue
    @($json.Sources.Packages.PackageIdentifier)
}

# 'installed' = todos sus paquetes están; 'partial' = solo algunos; 'missing' = ninguno; 'nowinget'.
function Get-AppStatus($app, $installedIds) {
    if ($null -eq $installedIds) { return 'nowinget' }
    $have = @($app.Ids | Where-Object { $installedIds -contains $_ }).Count
    if ($have -eq $app.Ids.Count) { 'installed' } elseif ($have) { 'partial' } else { 'missing' }
}

function Install-App($app) {
    $winget = Get-WingetPath
    if (-not $winget) {
        Say "winget no está disponible: instala 'Instalador de aplicación' desde Microsoft Store." Red
        return
    }
    Say "Instalando $($app.Name)..." Cyan
    foreach ($id in $app.Ids) {
        $wgArgs = @('install', '--id', $id, '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        if ($app.NoAdmin -and (Test-Admin)) {
            # Spotify no deja instalarse como administrador: se lanza con permisos de usuario normal
            Start-Process runas.exe -ArgumentList "/trustlevel:0x20000 `"winget $($wgArgs -join ' ')`""
            Say "  $id se instala en una ventana aparte (sin permisos de administrador)." Yellow
            continue
        }
        $out = & $winget @wgArgs 2>&1 | Out-String
        $code = $LASTEXITCODE
        switch ($code) {
            0           { Say "  OK    $id" Green; Write-Log "INSTALADO $id" }
            3010        { Say "  OK    $id (pide reiniciar)" Green; Write-Log "INSTALADO $id" }
            1641        { Say "  OK    $id (pide reiniciar)" Green; Write-Log "INSTALADO $id" }
            -1978335189 { Say "  YA ESTABA  $id (sin versión nueva)" Gray }
            -1978335135 { Say "  YA ESTABA  $id" Gray }
            default {
                $last = ($out -split "`n" | Where-Object { $_.Trim() } | Select-Object -Last 1)
                Say ("  FALLO $id (código 0x{0:X8}): {1}" -f $code, "$last".Trim()) Red
                Write-Log ("FALLO instalando {0}: 0x{1:X8}" -f $id, $code)
            }
        }
    }
}
