<#
  OptiXeo - optimizador de Windows hecho a medida para este PC
  (Ryzen 7 8700G / B650 / 32 GB / NVMe / Windows 10 Pro 22H2)

  - Todo es texto plano: lee el catálogo de abajo y verás exactamente qué toca.
  - Nada se descarga de internet. No instala nada.
  - Antes de cambiar algo guarda el valor anterior en .\backups\*.json
    y la opción [R] lo deja todo como estaba.

  Uso:  OptiXeo.bat                     (menú)
        OptiXeo.ps1 -Analyze            (solo informe, no cambia nada)
        OptiXeo.ps1 -Apply [-DryRun]    (aplica lo recomendado)
        OptiXeo.ps1 -Restore            (deshace la última copia)
#>
param([switch]$Analyze, [switch]$Apply, [switch]$Restore, [switch]$DryRun)

$ErrorActionPreference = 'Stop'
$Root      = $PSScriptRoot
$BackupDir = Join-Path $Root 'backups'
$LogFile   = Join-Path $Root 'OptiXeo.log'
$WslConfig = Join-Path $env:USERPROFILE '.wslconfig'

# Modulo de drivers (define funciones; se carga tambien al dot-sourcear desde la interfaz/worker).
. (Join-Path $Root 'OptiXeo-Drivers.ps1')

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin) -and -not $Analyze -and $MyInvocation.InvocationName -ne '.') {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    $argList += $PSBoundParameters.Keys | ForEach-Object { "-$_" }
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

# ============================================================================
#  CATÁLOGO  (Rec = $true -> entra en "Aplicar recomendado")
# ============================================================================
$CDM  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$Catalog = @(
    # ---- Servicios basura (no los usa nada de lo que tienes) ----
    @{Cat='Servicios'; Type='Service'; Name='DiagTrack';        Start='Disabled'; Rec=$true;  Why='Telemetría de Microsoft. Corre siempre y envía datos de uso.'}
    @{Cat='Servicios'; Type='Service'; Name='dmwappushservice'; Start='Disabled'; Rec=$true;  Why='Enrutador de mensajes WAP para telemetría/MDM.'}
    @{Cat='Servicios'; Type='Service'; Name='MapsBroker';       Start='Disabled'; Rec=$true;  Why='Mapas sin conexión. Está en Automático sin motivo.'}
    @{Cat='Servicios'; Type='Service'; Name='RetailDemo';       Start='Disabled'; Rec=$true;  Why='Modo demo de tiendas.'}
    @{Cat='Servicios'; Type='Service'; Name='Fax';              Start='Disabled'; Rec=$true;  Why='Fax.'}
    @{Cat='Servicios'; Type='Service'; Name='WMPNetworkSvc';    Start='Disabled'; Rec=$true;  Why='Compartir biblioteca de Windows Media Player en red.'}
    @{Cat='Servicios'; Type='Service'; Name='TrkWks';           Start='Disabled'; Rec=$true;  Why='Seguimiento de accesos directos en redes de dominio. Automático y corriendo.'}
    @{Cat='Servicios'; Type='Service'; Name='PcaSvc';           Start='Disabled'; Rec=$true;  Why='Asistente de compatibilidad ("este programa no se instaló bien"). Corriendo.'}
    @{Cat='Servicios'; Type='Service'; Name='wisvc';            Start='Disabled'; Rec=$true;  Why='Programa Windows Insider.'}
    @{Cat='Servicios'; Type='Service'; Name='GigabyteUpdateService'; Start='Manual'; Rec=$true; Why='Actualizador de Gigabyte en Automático y corriendo. Puedes actualizar desde GCC cuando quieras.'}
    @{Cat='Servicios'; Type='Service'; Name='edgeupdate';       Start='Manual';   Rec=$true;  Why='Actualizador de Edge en Automático. Sigue actualizando por su tarea programada.'}
    @{Cat='Servicios'; Type='Service'; Name='brave';            Start='Manual';   Rec=$true;  Why='Actualizador de Brave en Automático. Sigue actualizando por su tarea programada.'}
    @{Cat='Servicios'; Type='Service'; Name='GoogleUpdater*';   Start='Manual';   Rec=$true;  Why='Actualizadores de Google en Automático. Siguen actualizando por su tarea programada.'}
    @{Cat='Servicios'; Type='Service'; Name='stisvc';           Start='Manual';   Rec=$true;  Why='WIA (escáneres/cámaras). No tienes ninguno conectado; arranca solo si conectas uno.'}
    # opcionales
    @{Cat='Servicios'; Type='Service'; Name='AMD Crash Defender Service'; Start='Manual'; Rec=$false; Why='Recoge volcados cuando el driver de AMD se cuelga. Solo informa a AMD.'}
    @{Cat='Servicios'; Type='Service'; Name='lfsvc';            Start='Disabled'; Rec=$false; Why='Geolocalización. En un PC de escritorio casi nunca hace falta.'}
    @{Cat='Servicios'; Type='Service'; Name='WlanSvc';          Start='Manual';   Rec=$false; Why='Wi-Fi. Usas Ethernet; si lo pones en Manual el Wi-Fi no funcionará hasta iniciarlo.'}
    @{Cat='Servicios'; Type='Service'; Name='Spooler';          Start='Disabled'; Rec=$false; Why='Cola de impresión. Sin impresora física, PERO "Imprimir a PDF" deja de funcionar.'}
    @{Cat='Servicios'; Type='Service'; Name='SEMgrSvc';         Start='Disabled'; Rec=$true;  Why='Pagos y NFC. Tu PC no tiene NFC y estaba corriendo.'}
    @{Cat='Servicios'; Type='Service'; Name='WerSvc';           Start='Disabled'; Rec=$false; Why='Informe de errores a Microsoft. Si lo quitas, los cuelgues no se envían (el visor de eventos sigue funcionando).'}
    @{Cat='Servicios'; Type='Service'; Name='DPS';              Start='Disabled'; Rec=$false; Why='Diagnósticos. Sin él no van los solucionadores de problemas ni el historial de uso de red/batería.'}
    @{Cat='Servicios'; Type='Service'; Name='WdiServiceHost';   Start='Disabled'; Rec=$false; Why='Diagnósticos (va con DPS).'}
    @{Cat='Servicios'; Type='Service'; Name='WdiSystemHost';    Start='Disabled'; Rec=$false; Why='Diagnósticos (va con DPS).'}
    @{Cat='Servicios'; Type='Service'; Name='SysMain';          Start='Disabled'; Rec=$false; Why='Precarga apps en RAM. En NVMe la diferencia es mínima; desactivarlo baja la RAM "en caché", no la acelera.'}

    # ---- Tareas programadas de telemetría ----
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='Microsoft Compatibility Appraiser'; Rec=$true; Why='Escanea todo el disco para telemetría de compatibilidad. Pico de CPU/disco.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='ProgramDataUpdater'; Rec=$true; Why='Telemetría de programas instalados.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='MareBackup';         Rec=$true; Why='Telemetría de compatibilidad.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='PcaPatchDbTask';     Rec=$true; Why='Base de datos del asistente de compatibilidad.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Customer Experience Improvement Program\'; Name='Consolidator'; Rec=$true; Why='Programa de mejora de experiencia (CEIP).'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Customer Experience Improvement Program\'; Name='UsbCeip';      Rec=$true; Why='CEIP de USB.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Feedback\Siuf\'; Name='DmClient';                   Rec=$true; Why='Encuestas de opinión de Windows.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Feedback\Siuf\'; Name='DmClientOnScenarioDownload'; Rec=$true; Why='Encuestas de opinión de Windows.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Autochk\'; Name='Proxy'; Rec=$true; Why='Envía datos de autochk a SQM (telemetría).'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\DiskDiagnostic\'; Name='Microsoft-Windows-DiskDiagnosticDataCollector'; Rec=$true; Why='Envía diagnóstico de disco a Microsoft.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Maps\'; Name='MapsUpdateTask'; Rec=$true; Why='Actualiza mapas sin conexión (no los usas).'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Maps\'; Name='MapsToastTask';  Rec=$true; Why='Avisos de mapas.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Windows Error Reporting\'; Name='QueueReporting'; Rec=$true; Why='Envía informes de error pendientes.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\PI\'; Name='Sqm-Tasks'; Rec=$true; Why='Telemetría de calidad (SQM).'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\NetTrace\'; Name='GatherNetworkInfo'; Rec=$true; Why='Recoge información de red para diagnósticos.'}
    @{Cat='Tareas'; Type='Task'; Path='\Microsoft\Windows\Application Experience\'; Name='PcaWallpaperAppDetect'; Rec=$true; Why='Del asistente de compatibilidad (ya desactivado).'}

    # ---- Apps preinstaladas (se reinstalan gratis desde Microsoft Store) ----
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.BingSearch';      Rec=$true;  Why='Integración de Bing con la búsqueda.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.GetHelp';         Rec=$true;  Why='App "Obtener ayuda".'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.People';          Rec=$true;  Why='Contactos.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.Wallet';          Rec=$true;  Why='Cartera (pagos). Sin uso en PC.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.Windows.DevHome'; Rec=$true;  Why='Dev Home: Microsoft la abandonó.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.XboxApp';         Rec=$true;  Why='Antigua "Xbox Console Companion", ya retirada. No afecta a Game Bar ni a los juegos.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.WindowsAlarms';   Rec=$false; Why='Alarmas y reloj.'}
    @{Cat='Apps'; Type='Appx'; Name='Microsoft.YourPhone';       Rec=$false; Why='Vincular teléfono: PhoneExperienceHost siempre abierto (~150 MB). Quítalo si no conectas el móvil.'}
    @{Cat='Apps'; Type='Appx'; Name='MicrosoftWindows.CrossDevice'; Rec=$false; Why='Complemento de Vincular teléfono.'}

    # ---- Características de Windows (no liberan RAM: menos superficie de ataque y menos cosas que actualizar) ----
    @{Cat='Caracteristicas'; Type='Feature'; Name='MicrosoftWindowsPowerShellV2Root'; Rec=$true; Why='PowerShell 2.0: obsoleto y usado por malware para saltarse las protecciones.'}
    @{Cat='Caracteristicas'; Type='Feature'; Name='Internet-Explorer-Optional-amd64'; Rec=$true; Why='Internet Explorer 11, sin soporte.'}
    @{Cat='Caracteristicas'; Type='Feature'; Name='WorkFolders-Client';               Rec=$true; Why='Carpetas de trabajo (empresas).'}
    @{Cat='Caracteristicas'; Type='Feature'; Name='Printing-XPSServices-Features';    Rec=$true; Why='Impresora XPS. "Imprimir a PDF" no se toca.'}
    @{Cat='Caracteristicas'; Type='Feature'; Name='SmbDirect';                        Rec=$true; Why='SMB sobre RDMA: tu tarjeta de red no lo soporta.'}

    # ---- Privacidad / cosas que comen RAM en segundo plano ----
    @{Cat='Privacidad'; Type='Reg'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Value=0; Rec=$true; Why='Telemetría al mínimo permitido.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Value=0; Rec=$true; Why='ID de publicidad.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKCU:\Software\Microsoft\Siuf\Rules'; Name='NumberOfSIUFInPeriod'; Value=0; Rec=$true; Why='Ventanas de "danos tu opinión".'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SilentInstalledAppsEnabled';      Value=0; Rec=$true; Why='Windows instala apps "sugeridas" (Candy Crush y cía) sin preguntar.'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SystemPaneSuggestionsEnabled';    Value=0; Rec=$true; Why='Anuncios en el menú Inicio.'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SoftLandingEnabled';              Value=0; Rec=$true; Why='Consejos y trucos.'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SubscribedContent-338388Enabled'; Value=0; Rec=$true; Why='Sugerencias en Inicio.'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SubscribedContent-338389Enabled'; Value=0; Rec=$true; Why='Consejos al usar Windows.'}
    @{Cat='Privacidad'; Type='Reg'; Path=$CDM; Name='SubscribedContent-353694Enabled'; Value=0; Rec=$true; Why='Contenido sugerido en Configuración.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='BingSearchEnabled'; Value=0; Rec=$true; Why='Quita Bing de la búsqueda de Inicio (SearchApp usa menos RAM y va más rápido).'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='CortanaConsent'; Value=0; Rec=$true; Why='Cortana en la búsqueda.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'; Name='EnableFeeds'; Value=0; Rec=$true; Why='"Noticias e intereses" de la barra de tareas (un WebView de Edge siempre cargado).'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='StartupBoostEnabled';   Value=0; Rec=$true; Why='Edge precargado en segundo plano aunque no lo uses.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='BackgroundModeEnabled'; Value=0; Rec=$true; Why='Edge sigue vivo al cerrarlo.'}
    @{Cat='Privacidad'; Type='Reg'; Path='HKCU:\Software\Microsoft\GameBar'; Name='AutoGameModeEnabled'; Value=1; Rec=$true; Why='Modo Juego activado (prioriza el juego en primer plano).'}

    # ---- Inicio ----
    @{Cat='Inicio'; Type='Startup'; Hive='HKCU'; Name='Opera GX Browser Assistant'; Rec=$true;  Why='Asistente de Opera GX: proceso residente que no aporta nada.'}
    @{Cat='Inicio'; Type='Startup'; Hive='HKCU'; Name='Spotify';                    Rec=$false; Why='Spotify arranca minimizado con Windows (~950 MB ahora mismo).'}
    @{Cat='Inicio'; Type='Task';    Path='\'; Name='GCC'; Rec=$false; Why='Gigabyte Control Center al iniciar (~50 MB). Al arrancar vuelve a poner GigabyteUpdateService en Automático. Desactívalo si no usas su RGB/perfiles.'}

    # ---- WSL ----
    @{Cat='WSL'; Type='WslConfig'; Name='.wslconfig'; Rec=$true; Why='La VM de WSL (vmmem) se queda con 1-2,5 GB aunque Ubuntu esté parado. Esto la apaga a los 60 s sin uso y le hace devolver la RAM caché a Windows.'}
)

$WslConfigContent = @"
# Creado por OptiXeo
[wsl2]
vmIdleTimeout=60000

[experimental]
autoMemoryReclaim=dropcache
"@

$StartMap = @{ Auto = 2; Manual = 3; Disabled = 4 }

# ============================================================================
#  UTILIDADES
# ============================================================================
function Write-Log($msg) { Add-Content -Path $LogFile -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $msg) -Encoding UTF8 }
# La interfaz gráfica pone aquí su propio escritor; en consola va a Write-Host.
$script:LogSink = $null
function Say($msg, $color = 'Gray') {
    if ($script:LogSink) { & $script:LogSink $msg $color } else { Write-Host $msg -ForegroundColor $color }
}

function Get-Label($it) {
    switch ($it.Type) {
        'Service'   { "Servicio  $($it.Name) -> $($it.Start)" }
        'Task'      { "Tarea     $($it.Path)$($it.Name)" }
        'Reg'       { "Registro  $($it.Name) = $($it.Value)" }
        'Startup'   { "Inicio    $($it.Name)" }
        'WslConfig' { "WSL       $WslConfig" }
        'Appx'      { "App       $($it.Name)" }
        'Feature'   { "Función   $($it.Name)" }
    }
}

# Los nombres con * (GoogleUpdater*) se expanden a los servicios reales instalados.
function Get-ExpandedCatalog {
    foreach ($it in $Catalog) {
        if ($it.Type -eq 'Service' -and $it.Name.Contains('*')) {
            foreach ($s in (Get-Service -Name $it.Name -ErrorAction SilentlyContinue)) {
                $c = $it.Clone(); $c.Name = $s.Name; $c
            }
        } else { $it }
    }
}

# Algunos servicios (TrkWks...) tienen la clave del registro protegida: entonces se usa sc.exe,
# que pasa por el Administrador de servicios.
function Set-ServiceStart($name, [int]$start, [bool]$delayed) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
    try {
        Set-ItemProperty $k -Name Start -Value $start -Type DWord
        if ($start -eq 2) { Set-ItemProperty $k -Name DelayedAutostart -Value ([int]$delayed) -Type DWord }
    } catch {
        $mode = switch ($start) { 2 { if ($delayed) { 'delayed-auto' } else { 'auto' } } 3 { 'demand' } 4 { 'disabled' } default { throw "Start=$start no soportado" } }
        $out = & sc.exe config "$name" start= $mode 2>&1
        if ($LASTEXITCODE -ne 0) { throw "sc.exe: $out" }
    }
}

function Get-ApprovedKey($hive) { "${hive}:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" }

# Estado actual de un elemento (lo que se guarda en la copia de seguridad).
function Get-State($it) {
    switch ($it.Type) {
        'Service' {
            $k = "HKLM:\SYSTEM\CurrentControlSet\Services\$($it.Name)"
            if (-not (Test-Path $k)) { return $null }
            $p = Get-ItemProperty $k
            return @{ Start = $p.Start; Delayed = $p.DelayedAutostart }
        }
        'Task' {
            $t = Get-ScheduledTask -TaskPath $it.Path -TaskName $it.Name -ErrorAction SilentlyContinue
            if (-not $t) { return $null }
            return @{ State = [string]$t.State }
        }
        'Reg' {
            $p = Get-ItemProperty -Path $it.Path -Name $it.Name -ErrorAction SilentlyContinue
            if ($null -eq $p) { return @{ Exists = $false } }
            return @{ Exists = $true; Value = $p.($it.Name) }
        }
        'Startup' {
            $runKey = "$($it.Hive):\Software\Microsoft\Windows\CurrentVersion\Run"
            if ($null -eq (Get-ItemProperty $runKey -Name $it.Name -ErrorAction SilentlyContinue)) { return $null }
            $p = Get-ItemProperty (Get-ApprovedKey $it.Hive) -Name $it.Name -ErrorAction SilentlyContinue
            if ($null -eq $p) { return @{ Exists = $false } }
            return @{ Exists = $true; Bytes = [int[]]$p.($it.Name) }
        }
        'WslConfig' {
            if (Test-Path $WslConfig) { return @{ Exists = $true; Content = (Get-Content $WslConfig -Raw) } }
            return @{ Exists = $false }
        }
        'Appx' {
            $p = Get-AppxPackage -Name $it.Name | Select-Object -First 1
            if (-not $p) { return @{ Installed = $false } }
            return @{ Installed = $true; Location = $p.InstallLocation; Family = $p.PackageFamilyName }
        }
        'Feature' {
            # Win32_OptionalFeature se puede leer sin ser administrador (1 = activada)
            $f = Get-CimInstance Win32_OptionalFeature -Filter "Name='$($it.Name)'"
            if (-not $f) { return $null }
            return @{ Enabled = ($f.InstallState -eq 1) }
        }
    }
}

# $null = no existe en este PC; $true = ya está como queremos.
function Test-Applied($it, $st) {
    if ($null -eq $st) { return $null }
    switch ($it.Type) {
        'Service'   { $st.Start -eq $StartMap[$it.Start] -or ($it.Start -eq 'Manual' -and $st.Start -eq 4) }
        'Task'      { $st.State -eq 'Disabled' }
        'Reg'       { $st.Exists -and $st.Value -eq $it.Value }
        'Startup'   { $st.Exists -and ($st.Bytes[0] % 2 -eq 1) }   # impar = desactivado (igual que el Administrador de tareas)
        'WslConfig' { $st.Exists }
        'Appx'      { -not $st.Installed }
        'Feature'   { -not $st.Enabled }
    }
}

function Set-Optimization($it) {
    switch ($it.Type) {
        'Service' {
            Set-ServiceStart $it.Name $StartMap[$it.Start] $false
            if ($it.Start -eq 'Disabled') { Stop-Service -Name $it.Name -Force -ErrorAction SilentlyContinue }
        }
        'Task' { Disable-ScheduledTask -TaskPath $it.Path -TaskName $it.Name | Out-Null }
        'Reg' {
            if (-not (Test-Path $it.Path)) { New-Item -Path $it.Path -Force | Out-Null }
            Set-ItemProperty -Path $it.Path -Name $it.Name -Value $it.Value -Type DWord
        }
        'Startup' {
            $k = Get-ApprovedKey $it.Hive
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $it.Name -Value ([byte[]](3,0,0,0,0,0,0,0,0,0,0,0)) -Type Binary
        }
        'WslConfig' { Set-Content -Path $WslConfig -Value $WslConfigContent -Encoding ASCII }
        'Appx'      { Get-AppxPackage -Name $it.Name | Remove-AppxPackage }
        'Feature'   { Disable-WindowsOptionalFeature -Online -FeatureName $it.Name -NoRestart | Out-Null }
    }
}

function Restore-Optimization($it, $st) {
    switch ($it.Type) {
        'Service' {
            Set-ServiceStart $it.Name $st.Start ($st.Delayed -eq 1)
        }
        'Task' {
            if ($st.State -ne 'Disabled') { Enable-ScheduledTask -TaskPath $it.Path -TaskName $it.Name | Out-Null }
        }
        'Reg' {
            if ($st.Exists) { Set-ItemProperty -Path $it.Path -Name $it.Name -Value $st.Value -Type DWord }
            else { Remove-ItemProperty -Path $it.Path -Name $it.Name -ErrorAction SilentlyContinue }
        }
        'Startup' {
            $k = Get-ApprovedKey $it.Hive
            if ($st.Exists) { Set-ItemProperty -Path $k -Name $it.Name -Value ([byte[]]$st.Bytes) -Type Binary }
            else { Remove-ItemProperty -Path $k -Name $it.Name -ErrorAction SilentlyContinue }
        }
        'WslConfig' {
            if ($st.Exists) { Set-Content -Path $WslConfig -Value $st.Content -NoNewline -Encoding ASCII }
            else { Remove-Item $WslConfig -ErrorAction SilentlyContinue }
        }
        'Appx' {
            if (-not $st.Installed) { return }
            # Las apps de serie suelen dejar sus archivos en WindowsApps: se re-registran sin descargar nada.
            $manifest = Join-Path $st.Location 'AppxManifest.xml'
            if (Test-Path $manifest) { Add-AppxPackage -Register $manifest -DisableDevelopmentMode }
            else { throw "los archivos ya no están; reinstálala desde Microsoft Store ($($st.Family))" }
        }
        'Feature' {
            if ($st.Enabled) { Enable-WindowsOptionalFeature -Online -FeatureName $it.Name -NoRestart | Out-Null }
        }
    }
}

# Acepta "1,3,5-8" o "todo".
function Read-Selection($max) {
    $raw = Read-Host "Números (ej: 1,3,5-8), 'todo' o Enter para cancelar"
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    if ($raw -match '^\s*todo\s*$') { return 1..$max }
    $sel = foreach ($part in $raw -split ',') {
        if ($part -match '^\s*(\d+)\s*-\s*(\d+)\s*$') { [int]$Matches[1]..[int]$Matches[2] }
        elseif ($part -match '^\s*(\d+)\s*$') { [int]$Matches[1] }
    }
    $sel | Where-Object { $_ -ge 1 -and $_ -le $max } | Sort-Object -Unique
}

# ============================================================================
#  ACCIONES
# ============================================================================
function Show-Analysis {
    Say "`n================ ANÁLISIS ================" Cyan
    $os = Get-CimInstance Win32_OperatingSystem
    $installed = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB
    $visible = $os.TotalVisibleMemorySize / 1MB
    $free = $os.FreePhysicalMemory / 1MB
    Say ("RAM instalada {0:N0} GB | visible para Windows {1:N1} GB | libre {2:N1} GB" -f $installed, $visible, $free) White
    if ($installed - $visible -gt 2) {
        Say ("  ! {0:N1} GB reservados por la BIOS para la gráfica integrada (UMA Frame Buffer)." -f ($installed - $visible)) Yellow
        Say "    Es lo que más RAM te quita. Ver README: bajarlo a 4 GB o 'Auto' en la BIOS." Yellow
    }

    Say "`nTop procesos por RAM:" White
    Get-Process | Group-Object ProcessName | ForEach-Object {
        [pscustomobject]@{ Proceso = $_.Name; Num = $_.Count; MB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB) }
    } | Sort-Object MB -Descending | Select-Object -First 12 | Format-Table -AutoSize | Out-String | Write-Host

    $i = 0
    foreach ($cat in ($Catalog.Cat | Select-Object -Unique)) {
        Say "--- $cat ---" Cyan
        foreach ($it in (Get-ExpandedCatalog | Where-Object Cat -eq $cat)) {
            $i++
            $ok = Test-Applied $it (Get-State $it)
            $tag, $col = if ($null -eq $ok) { 'N/A     ', 'DarkGray' } elseif ($ok) { 'HECHO   ', 'Green' } else { 'PENDIENTE', 'Yellow' }
            $rec = if ($it.Rec) { '*' } else { ' ' }
            Write-Host ("{0,3} {1} [{2}] " -f $i, $rec, $tag) -ForegroundColor $col -NoNewline
            Write-Host (Get-Label $it) -ForegroundColor White
            Write-Host ("            {0}" -f $it.Why) -ForegroundColor DarkGray
        }
    }
    Say "`n* = recomendado   N/A = no existe en este PC" DarkGray
}

# Lo que falta por aplicar de $items, con su estado actual (para la copia).
function Get-Pending($items) {
    foreach ($it in $items) {
        $st = Get-State $it
        if ($null -ne $st -and -not (Test-Applied $it $st)) { @{ Obj = $it; Before = $st } }
    }
}

function Invoke-Optimize($items) {
    $todo = @(Get-Pending $items)
    if (-not $todo) { Say "`nNada que cambiar: ya está todo aplicado." Green; return }

    Say "`nSe van a aplicar $($todo.Count) cambios:" Cyan
    $todo | ForEach-Object { Say "  - $(Get-Label $_.Obj)" }
    if ($DryRun) { Say "`n(DryRun: no se ha cambiado nada)" Yellow; return }
    if ((Read-Host "`n¿Continuar? (s/n)") -notmatch '^[sS]') { return }
    Invoke-Changes $todo
}

# Aplica una lista de Get-Pending: punto de restauración, copia JSON paso a paso y log.
# $OnStep (opcional) se llama tras cada elemento: para que la interfaz se refresque.
function Invoke-Changes($todo, [scriptblock]$OnStep) {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        Checkpoint-Computer -Description 'OptiXeo' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Say "Punto de restauración creado." Green
    } catch { Say "Aviso: no se pudo crear punto de restauración ($($_.Exception.Message)). Se usa solo la copia de OptiXeo." Yellow }

    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    $file = Join-Path $BackupDir ("backup-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date))
    $done = @()
    foreach ($t in $todo) {
        try {
            Set-Optimization $t.Obj
            $done += $t
            Say "  OK    $(Get-Label $t.Obj)" Green
            Write-Log "APLICADO $(Get-Label $t.Obj)"
        } catch {
            Say "  FALLO $(Get-Label $t.Obj): $($_.Exception.Message)" Red
            Write-Log "FALLO $(Get-Label $t.Obj): $($_.Exception.Message)"
        }
        # se guarda tras cada paso, así la copia vale aunque se corte a medias
        $done | ConvertTo-Json -Depth 6 | Set-Content $file -Encoding UTF8
        if ($OnStep) { & $OnStep }
    }
    Say "`nCopia de seguridad: $file" Cyan
    Say "Reinicia para que los cambios de servicios surtan efecto completo." Yellow
    if ($done.Obj.Type -contains 'WslConfig') { Say "Para WSL: ejecuta 'wsl --shutdown' (o reinicia)." Yellow }
}

function Get-Backups { @(Get-ChildItem $BackupDir -Filter 'backup-*.json' -ErrorAction SilentlyContinue | Sort-Object Name -Descending) }

function Invoke-Restore {
    $files = Get-Backups
    if (-not $files) { Say "No hay copias de seguridad." Yellow; return }
    Say "`nCopias disponibles:" Cyan
    for ($n = 0; $n -lt $files.Count; $n++) { Say ("  {0}) {1}" -f ($n + 1), $files[$n].Name) }
    $pick = Read-Host "¿Cuál restaurar? (Enter = la más reciente)"
    $f = if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $files.Count) { $files[[int]$pick - 1] } else { $files[0] }
    Restore-Backup $f.FullName
}

# ConvertFrom-Json devuelve PSCustomObject; se pasa a hashtable para reutilizar las funciones
function ConvertTo-Hashtable($obj) {
    $h = @{}
    $obj.PSObject.Properties | ForEach-Object { $h[$_.Name] = $_.Value }
    $h
}

# Identifica un ajuste igual en el catálogo y en las copias.
function Get-ItemKey($it) { '{0}|{1}|{2}|{3}' -f $it.Type, $it.Path, $it.Hive, $it.Name }

# clave del ajuste -> estado que tenía antes de que OptiXeo lo cambiara (la copia más reciente gana)
function Get-BackupIndex {
    $idx = @{}
    foreach ($f in (Get-Backups | Sort-Object Name)) {
        try { $entries = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch { continue }
        foreach ($e in @($entries)) {
            $idx[(Get-ItemKey (ConvertTo-Hashtable $e.Obj))] = ConvertTo-Hashtable $e.Before
        }
    }
    $idx
}

# Deshace ajustes sueltos: lista de @{ Obj = ajuste; Before = estado guardado en la copia }.
function Undo-Items($list, [scriptblock]$OnStep) {
    foreach ($u in $list) {
        try {
            Restore-Optimization $u.Obj $u.Before
            Say "  DESHECHO $(Get-Label $u.Obj)" Green
            Write-Log "DESHECHO $(Get-Label $u.Obj)"
        } catch {
            Say "  FALLO al deshacer $(Get-Label $u.Obj): $($_.Exception.Message)" Red
            Write-Log "FALLO al deshacer $(Get-Label $u.Obj): $($_.Exception.Message)"
        }
        if ($OnStep) { & $OnStep }
    }
}

function Restore-Backup($path, [scriptblock]$OnStep) {
    $entries = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($e in @($entries)) {
        $it = ConvertTo-Hashtable $e.Obj
        $st = ConvertTo-Hashtable $e.Before
        try {
            Restore-Optimization $it $st
            Say "  RESTAURADO $(Get-Label $it)" Green
            Write-Log "RESTAURADO $(Get-Label $it)"
        } catch { Say "  FALLO $(Get-Label $it): $($_.Exception.Message)" Red }
        if ($OnStep) { & $OnStep }
    }
    Say "`nListo. Reinicia para completar." Yellow
}

function Get-RamInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    [pscustomobject]@{
        Installed = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB
        Visible   = $os.TotalVisibleMemorySize / 1MB
        Used      = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB
        Free      = $os.FreePhysicalMemory / 1MB
    }
}

function Get-TopProcesses($n = 8) {
    Get-Process | Group-Object ProcessName | ForEach-Object {
        [pscustomobject]@{ Name = $_.Name; Count = $_.Count; MB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB) }
    } | Sort-Object MB -Descending | Select-Object -First $n
}

function Clear-Temp {
    $before = (Get-PSDrive C).Free
    foreach ($dir in @($env:TEMP, "$env:windir\Temp")) {
        Get-ChildItem $dir -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Say ("Temporales de más de 1 día borrados. Liberado: {0:N0} MB" -f (((Get-PSDrive C).Free - $before) / 1MB)) Green
}

function Select-AndApply {
    $all = @(Get-ExpandedCatalog)
    for ($n = 0; $n -lt $all.Count; $n++) {
        $rec = if ($all[$n].Rec) { '*' } else { ' ' }
        Say ("{0,3} {1} {2}" -f ($n + 1), $rec, (Get-Label $all[$n]))
    }
    $sel = Read-Selection $all.Count
    if ($sel) { Invoke-Optimize ($sel | ForEach-Object { $all[$_ - 1] }) }
}

# ============================================================================
#  ENTRADA
# ============================================================================
# Cargado con ". .\OptiXeo.ps1" (desde la interfaz gráfica): solo las funciones.
if ($MyInvocation.InvocationName -eq '.') { return }

if ($Analyze) { Show-Analysis; return }
if ($Apply)   { Invoke-Optimize (Get-ExpandedCatalog | Where-Object { $_.Rec }); return }
if ($Restore) { Invoke-Restore; return }

while ($true) {
    Say "`n=========== OptiXeo ===========" Cyan
    Say " 1) Analizar (no cambia nada)"
    Say " 2) Aplicar lo recomendado"
    Say " 3) Elegir qué aplicar (incluye opcionales)"
    Say " 4) Limpiar temporales"
    Say " 5) Liberar RAM de WSL ahora (wsl --shutdown)"
    Say " 6) Drivers: detectar faltantes/actualizaciones (Windows Update)"
    Say " R) Restaurar una copia de seguridad"
    Say " 0) Salir"
    switch ((Read-Host 'Opción').Trim()) {
        '1' { Show-Analysis }
        '2' { Invoke-Optimize (Get-ExpandedCatalog | Where-Object { $_.Rec }) }
        '3' { Select-AndApply }
        '4' { Clear-Temp }
        '5' { wsl --shutdown; Say "VM de WSL apagada." Green }
        '6' { Show-DriverReport }
        { $_ -in 'r', 'R' } { Invoke-Restore }
        '0' { return }
    }
}
