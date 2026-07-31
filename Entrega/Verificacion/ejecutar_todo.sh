#!/usr/bin/env bash
# Ejecuta, sin intervencion manual, las 5 pruebas de verificacion del modelo
# de transporte (equivalente Linux/macOS de ejecutar_todo.ps1).
#
# Uso:
#   chmod +x ejecutar_todo.sh
#   ./ejecutar_todo.sh
set -uo pipefail
cd "$(dirname "$0")"

section() { echo; echo "==== $1 ===="; }
warn() { echo "$1"; }

section "0/5 Preparando dependencias de Python (openpyxl, scipy)"
python3 -m pip install -q openpyxl scipy

section "1/5 Construyendo la hoja de calculo con la estructura de Solver (build_xlsx.py)"
python3 build_xlsx.py

SOFFICE_PID=""
if command -v soffice >/dev/null 2>&1; then
  PROFILE_DIR="$(mktemp -d)"
  section "Levantando LibreOffice en modo servidor (segundo plano)"
  soffice --headless --invisible --nocrashreport --nodefault --norestore --nologo --nofirststartwizard \
    -env:UserInstallation="file://$PROFILE_DIR" \
    "--accept=socket,host=localhost,port=2002;urp;" >/dev/null 2>&1 &
  SOFFICE_PID=$!

  echo "Esperando a que LibreOffice quede listo para recibir conexiones..."
  LISTO=0
  for _ in $(seq 1 30); do
    sleep 1
    if (exec 3<>/dev/tcp/localhost/2002) 2>/dev/null; then
      exec 3>&- 3<&-
      LISTO=1
      break
    fi
  done

  if [ "$LISTO" = "1" ]; then
    section "2/5 Resolviendo con el Solver de LibreOffice Calc, motor lp_solve (run_solver.py)"
    python3 run_solver.py

    section "3/5 Cargando la solucion optima en la hoja (fill_solution.py)"
    python3 fill_solution.py
  else
    warn "LibreOffice no respondio a tiempo en el puerto 2002; se omiten los pasos 2 y 3."
  fi

  echo "Cerrando LibreOffice..."
  kill "$SOFFICE_PID" >/dev/null 2>&1
else
  warn "No se encontro 'soffice' en el PATH; se omiten los pasos 2 y 3."
  warn "Instala LibreOffice (libreoffice-calc) y vuelve a correr este script."
fi

section "4/5 Verificando con lp_solve por linea de comandos (modelo.lp)"
if command -v lp_solve >/dev/null 2>&1; then
  lp_solve -S4 modelo.lp
else
  warn "No se encontro lp_solve en el PATH. Instalalo (p. ej. 'apt-get install lp-solve') y vuelve a intentar."
fi

section "5/5 Verificando con Python + SciPy, motor HiGHS (verify_scipy.py)"
python3 verify_scipy.py

section "Listo"
echo "Revisa arriba: todas las pruebas que se hayan podido ejecutar deberian coincidir en Z = 4170."
