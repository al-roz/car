;
; Файл chess.inc.
;
; Заголовочный файл модуля chess.asm
;
; Маткин Илья Александрович     01.12.2013
;

;----------------------------------------

COLOR_WHITE equ     (200 + 200 shl 8 + 200 shl 16)
COLOR_BLACK equ     (100 + 100 shl 8 + 100 shl 16)


FIG_NULL    equ     0
FIG_PAWN    equ     1
FIG_CASTLE  equ     2
FIG_BISHOP  equ     3
FIG_KNIGHT  equ     4
FIG_QUEEN   equ     5
FIG_KING    equ     6
FIG_MAX     equ     6

FIGTYPE typedef dword;

;----------------------------------------

RegisterClassChessWindow proto hIns: HINSTANCE

CreateChessWindow proto hIns:HINSTANCE, parent:HWND, color:COLORREF, x:dword, y:dword, ftype: FIGTYPE

;----------------------------------------

;----------------------------------------
