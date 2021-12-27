;----------------------------------------

.686
.model flat, stdcall
option casemap:none

;----------------------------------------

include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc


include CarModel.inc
include Strings.mac

;----------------------------------------


.data
hwnd HWND ?


.data?

;----------------------------------------
.code

SetHwndMainWindow proc newHWND : HWND
	mov eax, newHWND
	mov hwnd, eax
	ret
SetHwndMainWindow endp

GetRoadCount proc 
	mov eax, ROAD_COUNT
	ret
GetRoadCount endp 

GetGameStatus proc
	invoke GetWindowLong, hwnd, 0
	mov eax, [eax].GameFild.gameStatus
	ret
GetGameStatus endp

GetGameFild proc uses edi
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.pGameFildStart
	ret
GetGameFild endp 
	
GetScore proc 
	invoke GetWindowLong, hwnd, 0
	mov eax, [eax].GameFild.score
	ret
GetScore endp  

GameFildIndexInit proc uses edi esi edx ecx  pFild : dword
	local i : dword
	local j : dword
	local pGameFild : ptr GameFild
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov esi, [edi].GameFild.roadCount
	mov edx, [edi].GameFild.roadSize
	mov [i],0
	
	mov edi, pFild
	.while [i] < esi
		mov [j], 0
		.while [j] < edx
			mov ecx, [i]
			mov [edi].Car.xCoord, ecx
			mov ecx, [j]
			mov [edi].Car.yCoord, ecx
			mov [edi].Car.cellType, CAR_NULL
			add edi, sizeof(Car)
			inc [j]
		.endw
		inc [i]
	.endw
	ret 
GameFildIndexInit endp 

InitMyCarOnGameFild proc uses edi edx ebx 
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, ROAD_COUNT
	xor edx, edx
	mov ebx, 2
	div ebx
	
	mov [edi].GameFild.MyCarYCoord, eax
	mov eax, ROAD_SIZE
	dec eax
	mov [edi].GameFild.MyCarXCoord, eax
	ret
InitMyCarOnGameFild endp 

SetGameOverStatus proc
	invoke GetWindowLong, hwnd, 0
	mov [eax].GameFild.gameStatus, GAME_OVER
	invoke crt_printf, $CTA("GAME OVER\n")
	ret
SetGameOverStatus endp

OffsetOnIJCar proc uses edi i : dword, j : dword
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.roadCount
	mov ebx, [i]
	imul eax, ebx
	add eax, j
	mov ebx, 12
	imul eax, ebx
	
	add eax, [edi].GameFild.pGameFildStart
ret
OffsetOnIJCar endp 

OffsetOnCarPos proc uses edi
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	invoke OffsetOnIJCar, [edi].GameFild.MyCarXCoord, [edi].GameFild.MyCarYCoord
	ret
OffsetOnCarPos endp

ClearCarOnFildByPos proc
	invoke OffsetOnCarPos
	mov [eax].Car.cellType, CAR_NULL
	ret
ClearCarOnFildByPos endp

SetCarOnFild proc carType : dword
	invoke OffsetOnCarPos
	mov ebx, carType
	.if [eax].Car.cellType == CAR_NULL
		mov [eax].Car.cellType, ebx
	.else
		invoke SetGameOverStatus
	.endif
	ret
SetCarOnFild endp 

InitGameModel proc roadSize : dword 
	local roadCell : dword 
	local i : dword
	local newGameFild : ptr GameFild

	invoke crt_calloc, 1, sizeof(GameFild)
	mov [newGameFild], eax
	
	xor edx, edx
	mov eax, roadSize
	imul eax, ROAD_COUNT
	push eax

	invoke crt_calloc, eax, sizeof(Car)	
	mov edi, [newGameFild]
	mov [edi].GameFild.pGameFildStart, eax

	mov [edi].GameFild.isClearLine, 0

	mov [edi].GameFild.score, 0

	mov [edi].GameFild.gameStatus, GAME_STARTED
	
	pop ebx
	mov edx, ebx
	lea ecx, [8*ebx]
	lea ecx, [ecx + 4*ebx]
	add eax, ecx

	mov [edi].GameFild.pGameFildEnd, eax
	mov eax, ROAD_COUNT
	mov [edi].GameFild.roadCount, eax
	
	mov eax, ROAD_SIZE
	mov [edi].GameFild.roadSize, eax

	invoke SetWindowLong, hwnd, 0, [newGameFild]
	
	invoke GameFildIndexInit, [edi].GameFild.pGameFildStart

	invoke InitMyCarOnGameFild

	;invoke OffsetOnIJCar, [edi].GameFild.MyCarXCoord, [edi].GameFild.MyCarYCoord
	
	invoke SetCarOnFild, CAR_PLAYER

	mov eax, [newGameFild]
			
ret
InitGameModel endp

MoveLeft proc
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.MyCarYCoord
	.if eax > 0
		invoke crt_printf, $CTA("Left\n\0")
		invoke ClearCarOnFildByPos
		dec [edi].GameFild.MyCarYCoord
		invoke SetCarOnFild, CAR_PLAYER
	.endif
	ret
MoveLeft endp

MoveRight proc
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.MyCarYCoord
	.if eax < ROAD_COUNT - 1
		invoke crt_printf, $CTA("Right\n\0")
		invoke ClearCarOnFildByPos
		inc [edi].GameFild.MyCarYCoord
		invoke SetCarOnFild, CAR_PLAYER
	.endif
	ret
MoveRight endp

MoveUp proc
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.MyCarXCoord
	.if eax > 2
		invoke crt_printf, $CTA("Top\n\0")
		invoke ClearCarOnFildByPos
		dec [edi].GameFild.MyCarXCoord
		invoke SetCarOnFild, CAR_PLAYER
	.endif
	ret
MoveUp endp

MoveDown proc
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov edi, pGameFild
	mov eax, [edi].GameFild.MyCarXCoord
	.if eax < ROAD_SIZE - 1
		invoke crt_printf, $CTA("Bottom\n\0")
		invoke ClearCarOnFildByPos
		inc [edi].GameFild.MyCarXCoord
		invoke SetCarOnFild, CAR_PLAYER
	.endif
	ret
	ret
MoveDown endp

ClearFirstLine proc
	local i : dword 
	local pGameFild : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov [i], 0
	mov edi, pGameFild
	mov edi, [edi].GameFild.pGameFildStart
	.while [i] < ROAD_COUNT
		mov [edi].Car.cellType, CAR_NULL
		add edi, sizeof(Car)
		inc [i]
	.endw
	ret
ClearFirstLine endp

CreateEnemyCar proc uses edi carPos : dword
	invoke crt_rand 
	and eax, 1
	.if eax == 1
		mov edi, carPos
		mov [edi].Car.cellType, CAR_ENEMY
	.endif
	ret
CreateEnemyCar endp 

CreateEnemyLine proc
	local i : dword 
	local pGameFild : dword
	local isSpawnCarNull : dword
	
	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov isSpawnCarNull, 0
	
	mov [i], 0
	mov edi, pGameFild
	.if [edi].GameFild.isClearLine == 0
		mov [edi].GameFild.isClearLine, 1

		mov edi, [edi].GameFild.pGameFildStart
		.while [i] < ROAD_COUNT
			invoke CreateEnemyCar, edi
			.if [edi].Car.cellType == CAR_NULL
				mov isSpawnCarNull, 1
			.endif
			add edi, sizeof(Car)
			inc [i]
		.endw		
		
		.if isSpawnCarNull == 0
			invoke OffsetOnIJCar, 0, 0
			mov [eax].Car.cellType, CAR_NULL
		.endif
	.else
		mov [edi].GameFild.isClearLine, 0
	.endif
	ret
CreateEnemyLine endp 

MoveLineDown proc lineNumber : dword
	local i : dword
	local pGameFild : dword
	local cellType : dword


	invoke GetWindowLong, hwnd, 0
	mov [pGameFild], eax

	mov [i], 0
	invoke OffsetOnIJCar, lineNumber, 0
	mov edi, eax	
	.while [i] < ROAD_COUNT
		mov eax, [edi].Car.cellType
		mov [cellType], eax
		.if [cellType] != CAR_PLAYER
			push edi
			mov eax, lineNumber
			add eax, 1
			invoke OffsetOnIJCar, eax, [i]
			pop edi
			mov ebx,[cellType]
			.if [eax].Car.cellType != CAR_PLAYER
				mov [eax].Car.cellType, ebx
			.elseif [eax].Car.cellType == CAR_PLAYER && ebx == CAR_ENEMY
				invoke SetGameOverStatus
			.endif
		.else
			push edi
			mov eax, lineNumber
			add eax, 1
			invoke OffsetOnIJCar, eax, [i]
			pop edi
			mov [eax].Car.cellType, CAR_NULL
		.endif
		
		add edi, sizeof(Car)
		inc [i]
	.endw

	ret
MoveLineDown endp 

MoveMatrixDown proc 
	local i : dword
	mov [i], ROAD_SIZE
	sub [i], 2 
	.while [i] > 0
		invoke MoveLineDown, [i]
		dec [i]
	.endw
		invoke MoveLineDown, 0
	ret
MoveMatrixDown endp

IncScore proc 
	invoke GetWindowLong, hwnd, 0
	inc [eax].GameFild.score
	ret
IncScore endp 
end