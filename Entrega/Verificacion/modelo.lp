/* Modelo de transporte - verificacion independiente con lp_solve (formato .lp) */
min: 4 XA1 + 6 XA2 + 8 XA3 + 10 XA4 + 12 XA5
   + 5 XB1 + 7 XB2 + 9 XB3 + 11 XB4 + 13 XB5
   + 6 XC1 + 8 XC2 + 10 XC3 + 12 XC4 + 14 XC5;

OFERTA_A: XA1 + XA2 + XA3 + XA4 + XA5 <= 100;
OFERTA_B: XB1 + XB2 + XB3 + XB4 + XB5 <= 150;
OFERTA_C: XC1 + XC2 + XC3 + XC4 + XC5 <= 200;

DEM_1: XA1 + XB1 + XC1 = 80;
DEM_2: XA2 + XB2 + XC2 = 90;
DEM_3: XA3 + XB3 + XC3 = 120;
DEM_4: XA4 + XB4 + XC4 = 60;
DEM_5: XA5 + XB5 + XC5 = 100;
