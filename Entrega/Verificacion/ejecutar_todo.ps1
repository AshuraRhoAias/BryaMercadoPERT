# Ejecuta, sin intervencion manual, las pruebas de verificacion del modelo
# de transporte descritas en el README.md e informe (incluye abrir LPSolve
# IDE con el modelo ya cargado, si esta instalado).
#
# Uso (PowerShell, parado en esta carpeta):
#   .\ejecutar_todo.ps1
# o, mas facil todavia, doble clic sobre ejecutar_todo.bat.
#
# El script busca Python, LibreOffice y LPSolve IDE, levanta LibreOffice en
# modo servidor, corre las verificaciones en orden y al final apaga
# LibreOffice. Si algo no esta instalado (LibreOffice, lp_solve o LPSolve
# IDE), lo avisa y sigue con lo que si puede ejecutar, en vez de detenerse.

$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

function Write-Section($t) {
    Write-Host ""
    Write-Host "==== $t ====" -ForegroundColor Cyan
}
function Write-Warn($t) {
    Write-Host $t -ForegroundColor Yellow
}

# ---------- 0) localizar interpretes ----------
$sysPython = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $sysPython) { $sysPython = (Get-Command python3 -ErrorAction SilentlyContinue).Source }
if (-not $sysPython) { $sysPython = (Get-Command py -ErrorAction SilentlyContinue).Source }
if (-not $sysPython) {
    Write-Host "No se encontro Python en el PATH. Instala Python 3 (python.org) y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}

$loCandidates = @(
    "C:\Program Files\LibreOffice\program\soffice.exe",
    "C:\Program Files (x86)\LibreOffice\program\soffice.exe"
)
$sofficeExe = $loCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
$loPython = $null
if ($sofficeExe) {
    $candidato = Join-Path (Split-Path $sofficeExe) "python.exe"
    if (Test-Path $candidato) { $loPython = $candidato }
}

Write-Section "0/6 Preparando dependencias de Python (openpyxl, scipy)"
& $sysPython -m pip install -q openpyxl scipy

# ---------- 1) construir la hoja de calculo ----------
Write-Section "1/6 Construyendo la hoja de calculo con la estructura de Solver (build_xlsx.py)"
& $sysPython build_xlsx.py

# ---------- 2-3) LibreOffice Calc Solver ----------
if ($sofficeExe -and $loPython) {
    Write-Section "Levantando LibreOffice en modo servidor (segundo plano)"
    $proc = Start-Process -FilePath $sofficeExe -ArgumentList @(
        "--headless", "--invisible", "--nocrashreport", "--nodefault",
        "--norestore", "--nologo", "--nofirststartwizard",
        "--accept=socket,host=localhost,port=2002;urp;"
    ) -PassThru -WindowStyle Hidden

    Write-Host "Esperando a que LibreOffice quede listo para recibir conexiones..."
    $listo = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        $test = Test-NetConnection -ComputerName localhost -Port 2002 -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($test) { $listo = $true; break }
    }

    if ($listo) {
        Write-Section "2/6 Resolviendo con el Solver de LibreOffice Calc, motor lp_solve (run_solver.py)"
        & $loPython run_solver.py

        Write-Section "3/6 Cargando la solucion optima en la hoja (fill_solution.py)"
        & $loPython fill_solution.py
    } else {
        Write-Warn "LibreOffice no respondio a tiempo en el puerto 2002; se omiten los pasos 2 y 3."
    }

    Write-Host "Cerrando LibreOffice..."
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
} else {
    Write-Warn "No se encontro LibreOffice (o su python.exe) en las rutas habituales; se omiten los pasos 2 y 3."
    Write-Warn "Instalalo desde https://www.libreoffice.org/download/download/ y vuelve a correr este script."
}

# ---------- 4) lp_solve por linea de comandos ----------
Write-Section "4/6 Verificando con lp_solve por linea de comandos (modelo.lp)"
$lpSolveExe = (Get-Command lp_solve.exe -ErrorAction SilentlyContinue).Source
if (-not $lpSolveExe) { $lpSolveExe = (Get-Command lp_solve -ErrorAction SilentlyContinue).Source }
if ($lpSolveExe) {
    & $lpSolveExe -S4 modelo.lp
} else {
    Write-Warn "No se encontro lp_solve.exe en el PATH."
    Write-Warn "Ojo: 'LPSolve IDE' es un programa grafico distinto y NO trae lp_solve.exe de linea de comandos."
    Write-Warn "Descarga la distribucion de consola (lp_solve_5.5.x_exe_win64.zip) desde"
    Write-Warn "https://sourceforge.net/projects/lpsolve/files/lpsolve/ y agrega esa carpeta al PATH."
}

# ---------- 5) LPSolve IDE (paso visual, no obligatorio) ----------
Write-Section "5/6 Abriendo LPSolve IDE con el modelo cargado (paso visual)"
$lpIdeCandidates = @(
    "C:\Program Files (x86)\LPSolve IDE\LpSolveIDE.exe",
    "C:\Program Files\LPSolve IDE\LpSolveIDE.exe"
)
$lpIde = $lpIdeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($lpIde) {
    try {
        $modeloPath = Join-Path $here "modelo.lp"
        Start-Process -FilePath $lpIde -ArgumentList "`"$modeloPath`"" | Out-Null
        Start-Sleep -Seconds 3
        # Intento automatico de resolver dentro del IDE (mejor esfuerzo: el atajo
        # exacto puede variar segun la version). El resultado numerico ya quedo
        # comprobado arriba con lp_solve/LibreOffice/SciPy, asi que si esto no
        # funciona en tu version, no afecta la validacion del modelo.
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait("{F9}")
        Write-Host "LPSolve IDE abierto con modelo.lp cargado."
    } catch {
        Write-Warn "Se abrio LPSolve IDE pero no se pudo automatizar el 'Resolver'. Puedes hacerlo manualmente desde el menu Model/Solve."
    }
} else {
    Write-Warn "No se encontro LPSolve IDE en las rutas habituales; se omite este paso (es solo visual, no afecta la validacion ya hecha arriba)."
}

# ---------- 6) Python + SciPy ----------
Write-Section "6/6 Verificando con Python + SciPy, motor HiGHS (verify_scipy.py)"
& $sysPython verify_scipy.py

Write-Section "Listo"
Write-Host "Revisa arriba: todas las pruebas que se hayan podido ejecutar deberian coincidir en Z = 4170."
