import uno
from com.sun.star.beans import PropertyValue
from com.sun.star.sheet import SolverConstraint
from com.sun.star.sheet.SolverConstraintOperator import LESS_EQUAL, EQUAL, GREATER_EQUAL
from com.sun.star.table import CellAddress
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
SHEET_IDX = 0

def addr(col, row):  # col,row 0-based
    return CellAddress(SHEET_IDX, col, row)

solver = smgr.createInstanceWithContext("com.sun.star.comp.Calc.LpsolveSolver", ctx)
solver.Document = doc
solver.Objective = addr(4, 16)          # E17
solver.Maximize = False

variables = []
for row in range(3, 6):       # rows 4-6 -> 0-based 3..5
    for col in range(1, 6):   # cols B-F -> 0-based 1..5
        variables.append(addr(col, row))
solver.Variables = tuple(variables)

constraints = []

def mk_constraint(left, op, right):
    c = SolverConstraint()
    c.Left = left
    c.Operator = op
    c.Right = right
    return c

# oferta: H_row <= G_row  (rows 4,5,6 -> 0-based 3,4,5 ; H col=7, G col=6)
for row in range(3, 6):
    constraints.append(mk_constraint(addr(7, row), LESS_EQUAL, addr(6, row)))

# demanda: col_row8 = col_row7  (row8->0-based7, row7->0-based6; cols B-F 1..5)
for col in range(1, 6):
    constraints.append(mk_constraint(addr(col, 7), EQUAL, addr(col, 6)))

# no negatividad
for v in variables:
    constraints.append(mk_constraint(v, GREATER_EQUAL, 0.0))

solver.Constraints = tuple(constraints)

solver.NonNegative = True
solver.solve()

success = solver.Success
print("Success:", success)
print("ResultValue:", solver.ResultValue)

doc.calculateAll()

solved_vals = []
for v in variables:
    cell = sheet.getCellByPosition(v.Column, v.Row)
    solved_vals.append(cell.getValue())
print("Solved decision variables (from sheet cells):", solved_vals)

obj_cell = sheet.getCellByPosition(4, 16)
print("Objective cell value (from sheet):", obj_cell.getValue())

# Save as xlsx (overwrite) and also export a screenshot via pdf conversion of just this sheet
doc.store()

doc.close(False)
print("done")
