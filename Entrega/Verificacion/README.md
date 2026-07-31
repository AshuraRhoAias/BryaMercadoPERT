# Pruebas de verificación del modelo de transporte

Esta carpeta contiene los scripts y las salidas reales de las cinco (o más) comprobaciones
independientes descritas en las secciones 4.5 y 4.6 del informe (`Entrega/Informe_Optimizacion_Transporte_Bryan_Mercado.pdf`).
No son capturas de pantalla ni resultados escritos a mano: son los archivos que se ejecutaron
y las salidas que produjeron, tal cual, para que cualquiera pueda reproducirlos.

## Orden de ejecución

1. **`build_xlsx.py`** — genera `Modelo_Transporte_Solver.xlsx` (en `Entrega/`) con la
   estructura de celdas, restricciones y celda objetivo tal como se configuraría en Excel
   Solver. Salida: `salida_build_xlsx.txt`.
2. **`run_solver.py`** — abre ese archivo con LibreOffice Calc (vía UNO/Python) y ejecuta
   su Solver integrado (motor `lp_solve`). Requiere que LibreOffice esté escuchando en el
   puerto 2002 (ver comando al inicio del propio script). Salida real:
   `salida_run_solver.txt` → `Success: True`, `ResultValue: 4170.0`.
3. **`fill_solution.py`** — carga la solución óptima (obtenida a mano en las secciones 4.2–4.4)
   en las celdas de variables del mismo archivo, para dejarlo en el estado "resuelto" que se
   ve en la captura del informe. Salida: `salida_fill_solution.txt` → objetivo recalculado
   = 4170.0.
4. **`modelo.lp`** — el mismo modelo, pero escrito directamente en el formato de texto de
   `lp_solve`, resuelto por línea de comandos (`lp_solve -S4 modelo.lp`), sin pasar por
   ninguna hoja de cálculo. Salida real: `salida_lp_solve.txt` → función objetivo 4170.00000000,
   con una asignación de rutas distinta a la de la esquina noroeste (evidencia real de que el
   problema tiene más de una solución óptima) y los precios duales de cada restricción.
5. **`verify_scipy.py`** — el mismo modelo, resuelto en Python con `scipy.optimize.linprog`
   (motor HiGHS), independiente de LibreOffice y de lp_solve. Salida real:
   `salida_verify_scipy.txt` → objetivo 4170.0, con una tercera asignación de rutas distinta
   a las dos anteriores.

## Cómo reproducirlo

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
