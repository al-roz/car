CAR_NULL    equ     0
CAR_PLAYER	equ     1
CAR_ENEMY	equ     2

ROAD_COUNT equ 3
ROAD_SIZE  equ 10

GAME_STARTED	equ	0
GAME_OVER		equ	1


;----------------------------------------
Car struct
	xCoord dword ?
	yCoord dword ?
	cellType dword ? 
Car ends

GameFild struct 
	pGameFildStart dword ?
	pGameFildEnd dword ?
	roadSize dword ? 
	roadCount dword ? 
	score dword ?
	gameStatus dword ?
	isClearLine dword ?
	MyCarXCoord dword ?
	MyCarYCoord dword ?
GameFild ends 
;----------------------------------------

;----------------------------------------
GetRoadCount proto

GetGameFild  proto

MoveLeft proto

MoveRight proto

MoveUp proto

MoveDown proto

CreateEnemyLine proto

ClearFirstLine proto

SetHwndMainWindow proto newHWND : HWND

InitGameModel proto roadSize : dword 

MoveLineDown proto lineNumber : dword

MoveMatrixDown proto

GetGameStatus proto

IncScore proto

GetScore proto

;----------------------------------------
;----------------------------------------