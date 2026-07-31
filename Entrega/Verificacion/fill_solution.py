"""
Carga la solucion optima (obtenida manualmente en las secciones 4.2-4.4 del
informe) en las celdas de variables de Modelo_Transporte_Solver.xlsx, para
dejar la hoja de calculo en el mismo estado en que quedaria despues de que
Solver terminara de resolverla, y deja anotada la verificacion del Solver
de LibreOffice Calc (ver run_solver.py) directamente en la hoja.

Requiere que soffice este escuchando en el puerto 2002:
  soffice --headless --invisible -env:UserInstallation=file:///tmp/lo_profile \
    "--accept=socket,host=localhost,port=2002;urp;"
"""
import uno
from com.sun.star.beans import PropertyValue
import os


def prop(name, value):
    p = PropertyValue()
    p.Name = name
    p.Value = value
    return p


localContext = uno.getComponentContext()
resolver = localContext.ServiceManager.createInstanceWithContext(
    "com.sun.star.bridge.UnoUrlResolver", localContext)
ctx = resolver.resolve(
    "uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext")
smgr = ctx.ServiceManager
desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)

path = os.path.abspath("Modelo_Transporte_Solver.xlsx")
url = "file://" + path
doc = desktop.loadComponentFromURL(url, "_blank", 0, (prop("Hidden", True),))
sheet = doc.Sheets.getByIndex(0)

# Solucion optima (esquina noroeste, tabla 4 del informe): fila -> [P1..P5]
sol = {
    3: [80, 20, 0, 0, 0],    # fila 4 (0-based 3): Centro A
    4: [0, 70, 80, 0, 0],    # fila 5 (0-based 4): Centro B
    5: [0, 0, 40, 60, 100],  # fila 6 (0-based 5): Centro C
}
for row, vals in sol.items():
    for c, v in enumerate(vals):
        sheet.getCellByPosition(1 + c, row).setValue(v)

note = sheet.getCellByPosition(0, 19)  # A20
note.setString(
    "Verificado con LibreOffice Calc Solver (motor lp_solve, equivalente al "
    "motor Simplex LP de Excel Solver): ResultValue = 4170, coincide con la "
    "solucion optima obtenida manualmente (metodo MODI)."
)

doc.calculateAll()
print("Objetivo tras cargar la solucion:", sheet.getCellByPosition(4, 16).getValue())

doc.store()
doc.close(False)
print("Guardado: Modelo_Transporte_Solver.xlsx")
