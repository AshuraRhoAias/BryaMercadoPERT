import numpy as np
from scipy.optimize import linprog

centros = ["A", "B", "C"]
puntos = [1, 2, 3, 4, 5]
costos = {
    "A": [4, 6, 8, 10, 12],
    "B": [5, 7, 9, 11, 13],
    "C": [6, 8, 10, 12, 14],
}
oferta = {"A": 100, "B": 150, "C": 200}
demanda = [80, 90, 120, 60, 100]

# variables ordenadas: XA1..XA5, XB1..XB5, XC1..XC5
c = costos["A"] + costos["B"] + costos["C"]

# restricciones de oferta (<=): 3 filas x 15 columnas
A_ub = []
b_ub = []
for i, ci in enumerate(centros):
    row = [0] * 15
    for j in range(5):
        row[i * 5 + j] = 1
    A_ub.append(row)
    b_ub.append(oferta[ci])

# restricciones de demanda (=): 5 filas x 15 columnas
A_eq = []
b_eq = []
for j in range(5):
    row = [0] * 15
    for i in range(3):
        row[i * 5 + j] = 1
    A_eq.append(row)
    b_eq.append(demanda[j])

res = linprog(c, A_ub=A_ub, b_ub=b_ub, A_eq=A_eq, b_eq=b_eq, bounds=(0, None), method="highs")

print("Status:", res.status, res.message)
print("Objetivo (Z):", res.fun)
labels = [f"X{ci}{j}" for ci in centros for j in puntos]
for lab, val in zip(labels, res.x):
    if val > 1e-6:
        print(f"{lab} = {val:.1f}")
