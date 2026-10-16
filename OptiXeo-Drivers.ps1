<#
  OptiXeo-Drivers.ps1 - Modulo de drivers para OptiXeo.
  Detecta dispositivos con problema / sin driver (PnP) y actualizaciones de driver
  del catalogo OFICIAL de Windows Update, y las instala. Vendor-aware (AMD/Intel/NVIDIA).

  Sin nube de terceros: solo SetupAPI/PnP + Windows Update (firmados).
  Se carga con ". OptiXeo-Drivers.ps1" desde el motor y la interfaz.
#>

$VendorSource = @{
    'NVIDIA' = 'nvidia.com/Download (o la app NVIDIA)'
    'AMD'    = 'amd.com/support (AMD Software: Adrenalin)'
    'Intel'  = 'Intel Driver & Support Assistant'
}

function Resolve-GpuVendor($name) {
    if     ($name -match 'NVIDIA|GeForce|Quadro|RTX|GTX') { 'NVIDIA' }
    elseif ($name -match 'AMD|Radeon|ATI')                { 'AMD' }
    elseif ($name -match 'Intel|Iris|UHD|Arc')            { 'Intel' }
    else   { $null }
}

# Busca drivers nuevos en Windows Update. Intenta el servicio de drivers y cae al servicio por defecto.
function Search-WuDrivers {
    $session = New-Object -ComObject Microsoft.Update.Session
    try {
        $s = $session.CreateUpdateSearcher()
        $s.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'   # Windows Update driver service
        $s.ServerSelection = 3                                   # Others
        return $s.Search("Type='Driver' AND IsInstalled=0")
    } catch {
        $s = $session.CreateUpdateSearcher()
        $s.ServerSelection = 2                                   # WindowsUpdate por defecto
        return $s.Search("Type='Driver' AND IsInstalled=0")
    }
}

# Lista unificada para la interfaz. Cada item es un hashtable:
#   @{ Kind='update'|'problem'|'gpu'; Title; Detail; Vendor; Installable [bool] }
function Get-DriverItems {
    $items = New-Object System.Collections.ArrayList

    # 1) GPU(s): informativo + fuente oficial del fabricante (WU suele ir atras en GPU)
    foreach ($g in (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)) {
        $v   = Resolve-GpuVendor "$($g.Name) $($g.AdapterCompatibility)"
        $src = if ($v) { $VendorSource[$v] } else { 'Windows Update cubre el baseline' }
        [void]$items.Add(@{
            Kind='gpu'; Title=$g.Name; Vendor=$v
            Detail=("Instalada v{0}. Para la ultima gamer: {1}" -f $g.DriverVersion, $src)
            Installable=$false
        })
    }

    # 2) Dispositivos con problema / sin driver (code 28 = falta driver)
    foreach ($d in (Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Error' })) {
        $pc  = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_ProblemCode' -ErrorAction SilentlyContinue).Data
        $txt = if ($pc -eq 28) { 'Sin driver instalado (codigo 28)' } else { "Con problema (codigo $pc)" }
        [void]$items.Add(@{
            Kind='problem'; Title=$d.FriendlyName; Vendor=$d.Class
            Detail=$txt; Installable=$false
        })
    }

    # 3) Actualizaciones de driver via Windows Update (instalables)
    try {
        foreach ($u in (Search-WuDrivers).Updates) {
            [void]$items.Add(@{
                Kind='update'; Title=$u.Title; Vendor='Windows Update'
                Detail='Driver mas nuevo, firmado. Windows guarda el anterior para revertir.'
                Installable=$true
            })
        }
    } catch {
        Say "No se pudo consultar Windows Update: $($_.Exception.Message)" Yellow
    }

    ,$items.ToArray()
}

# Instala los updates cuyo Title este en $titles. $OnStep se llama por cada uno (para la barra).
function Install-DriverUpdates($titles, [scriptblock]$OnStep) {
    $session = New-Object -ComObject Microsoft.Update.Session
    $coll = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($u in (Search-WuDrivers).Updates) {
        if ($titles -contains $u.Title) {
            if (-not $u.EulaAccepted) { $u.AcceptEula() }
            [void]$coll.Add($u)
        }
    }
    if ($coll.Count -eq 0) { Say 'No se encontraron esos drivers para instalar.' Yellow; return }

    Say ("Descargando {0} driver(s) desde Windows Update..." -f $coll.Count) Cyan
    $dl = $session.CreateUpdateDownloader(); $dl.Updates = $coll; $null = $dl.Download()
    foreach ($u in $coll) {
        $one = New-Object -ComObject Microsoft.Update.UpdateColl
        [void]$one.Add($u)
        try {
            $inst = $session.CreateUpdateInstaller(); $inst.Updates = $one
            $res  = $inst.Install()
            $ok   = switch ($res.ResultCode) { 2 {'OK'} 3 {'OK con avisos'} default {'FALLO'} }
            $col  = if ($res.ResultCode -eq 2) { 'Green' } else { 'Yellow' }
            Say ("  {0}  {1}" -f $ok, $u.Title) $col
        } catch {
            Say ("  FALLO  {0}: {1}" -f $u.Title, $_.Exception.Message) Red
        }
        if ($OnStep) { & $OnStep }
    }
    Say 'Instalacion de drivers terminada. Reinicia si se instalo una GPU.' Cyan
}

# Informe por consola (opcion del menu de OptiXeo.ps1).
function Show-DriverReport {
    Say "`n============== DRIVERS ==============" Cyan
    foreach ($d in (Get-DriverItems)) {
        $tag, $col = switch ($d.Kind) {
            'update'  { 'ACTUALIZAR', 'Cyan' }
            'problem' { 'PROBLEMA  ', 'Red' }
            'gpu'     { 'GPU       ', 'White' }
        }
        Say ("[{0}] {1}" -f $tag, $d.Title) $col
        Say ("             {0}" -f $d.Detail) DarkGray
    }
    Say "`nPara instalar: usa la pestana 'Drivers' de la interfaz." DarkGray
}
