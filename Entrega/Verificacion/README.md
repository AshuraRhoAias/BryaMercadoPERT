# Pruebas de verificación del modelo de transporte

Esta carpeta contiene los scripts y las salidas reales de las cinco (o más) comprobaciones
independientes descritas en las secciones 4.5 y 4.6 del informe (`Entrega/Informe_Optimizacion_Transporte_Bryan_Mercado.pdf`).
No son capturas de pantalla ni resultados escritos a mano: son los archivos que se ejecutaron
y las salidas que produjeron, tal cual, para que cualquiera pueda reproducirlos.

## Ejecutar todo con un solo comando

No hace falta escribir cada paso a mano. Ya viene armado un script que hace todas las
verificaciones seguidas, sin intervención manual (en Windows, incluso abre LPSolve IDE
solo, con el modelo ya cargado), y avisa (sin detenerse) si algún programa no está
instalado.

**Windows** — doble clic sobre `ejecutar_todo.bat` (o, en PowerShell, parado en esta carpeta):

```powershell
.\ejecutar_todo.ps1
```

**Linux / macOS**, parado en esta carpeta:

```bash
chmod +x ejecutar_todo.sh
./ejecutar_todo.sh
```

Requisitos previos (una sola vez): tener instalados **Python 3**, **LibreOffice** y, opcionalmente,
**lp_solve** (línea de comandos, no la "LPSolve IDE" gráfica, ver nota más abajo). El script
instala solo `openpyxl` y `scipy` vía pip; lo demás debe estar ya instalado en el sistema.

Al terminar, la consola muestra todas las corridas una tras otra; todas deberían coincidir en
el mismo costo óptimo: **Z = 4 170**.

### Nota para Windows: "LPSolve IDE" no es lo mismo que "lp_solve"

Si instalaste **LPSolve IDE** (un programa gráfico de terceros), el ejecutable que trae es
`LpSolveIDE.exe`, no `lp_solve.exe`. El comando de línea de comandos que usa este proyecto
(`lp_solve -S4 modelo.lp`) necesita el paquete de **consola** de lp_solve, que es un `.zip`
distinto: descarga `lp_solve_5.5.x_exe_win64.zip` desde
<https://sourceforge.net/projects/lpsolve/files/lpsolve/>, descomprímelo, y agrega esa carpeta
(la que contiene `lp_solve.exe`) al PATH de Windows. Si no lo instalas, el script simplemente
se salta ese paso y sigue con los demás; el modelo igual queda verificado por las otras vías.

Aun así, si `ejecutar_todo.ps1` encuentra **LPSolve IDE** instalado en una de sus rutas
habituales (`C:\Program Files (x86)\LPSolve IDE\LpSolveIDE.exe` o `C:\Program Files\...`), lo
abre automáticamente con `modelo.lp` ya cargado y le manda la tecla F9 para intentar resolverlo
en la propia interfaz, como confirmación visual extra. Este paso es "mejor esfuerzo": si el
atajo de esa versión del IDE no es F9, la ventana igual queda abierta con el modelo cargado
(se resuelve con un clic en Model → Solve), y de todos modos el resultado numérico ya quedó
comprobado por los pasos anteriores (LibreOffice Solver, lp_solve y SciPy), así que no depende
de que esta automatización funcione al 100 %.

### Nota técnica: por qué hay que usar el Python de LibreOffice para `run_solver.py`

`run_solver.py` y `fill_solution.py` usan el módulo `uno` para controlar LibreOffice Calc,
y ese módulo solo existe dentro del propio Python que trae LibreOffice instalado
(`C:\Program Files\LibreOffice\program\python.exe` en Windows), no en un Python normal
instalado aparte. El script `ejecutar_todo.ps1` ya detecta esa ruta automáticamente y usa el
Python correcto para esos dos pasos, y el Python del sistema para el resto (`build_xlsx.py` y
`verify_scipy.py`, que no necesitan `uno`).

## Qué hace cada paso (por si se quiere correr uno por uno)

1. **`build_xlsx.py`** — genera `Modelo_Transporte_Solver.xlsx` (en `Entrega/`) con la
   estructura de celdas, restricciones y celda objetivo tal como se configuraría en Excel
   Solver. Salida: `salida_build_xlsx.txt`.
2. **`run_solver.py`** — abre ese archivo con LibreOffice Calc (vía UNO/Python) y ejecuta
   su Solver integrado (motor `lp_solve`). Requiere que LibreOffice esté escuchando en el
   puerto 2002 (el script `ejecutar_todo` ya se encarga de levantarlo y esperarlo). Salida
   real: `salida_run_solver.txt` → `Success: True`, `ResultValue: 4170.0`.
3. **`fill_solution.py`** — carga la solución óptima (obtenida a mano en las secciones 4.2–4.4
   del informe) en las celdas de variables del mismo archivo, para dejarlo en el estado
   "resuelto" que se ve en la captura del informe. Salida: `salida_fill_solution.txt` →
   objetivo recalculado = 4170.0.
4. **`modelo.lp`** — el mismo modelo, pero escrito directamente en el formato de texto de
   `lp_solve`, resuelto por línea de comandos (`lp_solve -S4 modelo.lp`), sin pasar por
   ninguna hoja de cálculo. Salida real: `salida_lp_solve.txt` → función objetivo 4170.00000000,
   con una asignación de rutas distinta a la de la esquina noroeste (evidencia real de que el
   problema tiene más de una solución óptima) y los precios duales de cada restricción.
5. **LPSolve IDE** (solo Windows, solo si está instalado) — el script lo abre con `modelo.lp`
   ya cargado y le manda la tecla F9, como confirmación visual adicional. Es un paso "mejor
   esfuerzo" (no todos los atajos de teclado son iguales en todas las versiones) y no es
   necesario para validar el modelo: eso ya lo hacen los pasos 2 y 4 (LibreOffice Solver y
   lp_solve por línea de comandos).
6. **`verify_scipy.py`** — el mismo modelo, resuelto en Python con `scipy.optimize.linprog`
   (motor HiGHS), independiente de LibreOffice y de lp_solve. Salida real:
   `salida_verify_scipy.txt` → objetivo 4170.0, con una tercera asignación de rutas distinta
   a las dos anteriores.

## Reproducir un paso suelto a mano (Linux/macOS)

```bash
pip install openpyxl scipy
sudo apt-get install libreoffice-calc lp-solve

# 1) construir la hoja de calculo
python3 build_xlsx.py

# 2) levantar LibreOffice en modo servidor (en segundo plano)
soffice --headless --invisible -env:UserInstallation=file:///tmp/lo_profile \
  "--accept=socket,host=localhost,port=2002;urp;" &

# 3) resolver con el Solver de Calc y cargar la solucion
python3 run_solver.py
python3 fill_solution.py

# 4) verificar con lp_solve por linea de comandos
lp_solve -S4 modelo.lp

# 5) verificar con Python/SciPy
python3 verify_scipy.py
```

Las cinco corridas (más el método de la esquina noroeste y el método de Vogel, hechos a mano
y documentados en el propio informe) coinciden en el mismo costo óptimo: **Z = 4 170**.
