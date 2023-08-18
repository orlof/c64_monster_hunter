REM ****************************************************************************
REM
REM ****************************************************************************
SHARED CONST COLOR_MEMORY = $D800

DIM SHARED RegBorderColor AS BYTE @53280
DIM SHARED RegScreenColor AS BYTE @53281

DIM SHARED ZP_L0 AS LONG @$24
DIM SHARED ZP_L1 AS LONG @$21
DIM SHARED ZP_I0 AS INT @$1f

DIM SHARED ZP_W0 AS WORD @$19
DIM SHARED ZP_W1 AS WORD @$1b
DIM SHARED ZP_W2 AS WORD @$1d

DIM SHARED ZP_B0 AS BYTE @$15
DIM SHARED ZP_B1 AS BYTE @$16
DIM SHARED ZP_B2 AS BYTE @$17
DIM SHARED ZP_B3 AS BYTE @$18

THE_END: