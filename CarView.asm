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

include CarView.inc
include CarModel.inc
include Strings.mac

;----------------------------------------

RGB macro r:REQ, g:REQ, b:REQ
	tmp = (r) or ((g) shl 8) or ((b) shl 16)
	%echo @CatStr(%tmp)
    exitm <tmp>
endm
;----------------------------------------


;----------------------------------------
.data
hdc HDC ?


.data?

;----------------------------------------
.code

SetHDC proc newHDC : HDC
	mov eax, [newHDC]
	mov hdc, eax
	ret
SetHDC endp

GetOneRoadSize proc	
	xor edx, edx
	mov ebx, ROAD_COUNT 
	div ebx	
GetOneRoadSize endp

DrawSeparatorsLine proc windowRect : ptr RECT
	local lineColorBrush : HBRUSH
	local colorBrush : COLORREF
	local drawPosition : dword 
	local roadSize : dword
	local i : dword
	local rect : RECT
	local roadCount : dword 
	local left_border : dword
	local right_border : dword
	local top_border : dword
	local bottom_border : dword

	mov [colorBrush], RGB(200,200,200)
	invoke CreateSolidBrush, [colorBrush]
	mov [lineColorBrush], eax

	mov eax, ROAD_COUNT
	mov [roadCount], eax

	mov edi, windowRect
	mov eax, [edi].RECT.left
	mov left_border, eax

	mov eax, [edi].RECT.right
	mov right_border, eax

	mov eax, [edi].RECT.top
	mov top_border, eax

	mov eax, [edi].RECT.bottom
	mov bottom_border, eax
	

	mov eax, right_border
	sub eax, left_border
	xor edx, edx
	mov ebx, [roadCount]
	div ebx
	mov [roadSize], eax
	
	mov [i], 1
	mov ecx, [i]
	mov eax, left_border
	mov [drawPosition], eax
	.while ecx < [roadCount]
		mov eax, CarSize
		add [drawPosition], eax 
		
		mov eax, [drawPosition]
		mov [rect].left, eax
		mov edx, top_border
		mov [rect].top, edx
		inc [rect].top
		add eax, 10
		mov [rect].right, eax	
		mov edx, bottom_border
		mov [rect].bottom, edx
		dec [rect].bottom
	
		invoke FillRect, [hdc], addr [rect], [lineColorBrush]
		add [drawPosition], 10
		inc [i]
		mov ecx, [i]
	.endw

	invoke DeleteObject, [lineColorBrush]

	ret
DrawSeparatorsLine endp

CreateGameRoad proc windowRect : ptr RECT
	local pen:HPEN
	local color_brush:COLORREF
	local black_brush:HBRUSH
	local white_brush:HBRUSH
	local gray_brush:HBRUSH
	local i:dword
	local j:dword
	local rect:ptr RECT

	mov eax, windowRect
	mov rect, eax

	mov [color_brush], RGB(0,0,0)
	invoke CreateSolidBrush, [color_brush]
	mov [black_brush], eax
		
	mov [color_brush], RGB(255,255,255)
	invoke CreateSolidBrush, [color_brush]
	mov [white_brush], eax

	mov [color_brush], RGB(128,128,128)
	invoke CreateSolidBrush, [color_brush]
	mov [gray_brush], eax


    invoke CreatePen, PS_SOLID, 4, RGB(255,0,0)
    mov [pen],eax
	
	invoke SelectObject, [hdc], [pen]		

	invoke FillRect, [hdc], [rect], [gray_brush]

	invoke FrameRect, [hdc], [rect], [pen]

	invoke DrawSeparatorsLine, [rect]

    invoke DeleteObject, pen
    invoke DeleteObject, [black_brush]
	invoke DeleteObject, [white_brush]
	invoke DeleteObject, [gray_brush]

	ret
CreateGameRoad endp

DrawCar proc x : dword, y : dword, color : HBRUSH
	local rect : RECT

	mov eax, [x]
	mov [rect].left, eax
	mov edx, [y]
	mov [rect].top, edx
	inc [rect].top
	
	mov [rect].right, eax
	add [rect].right, CarSize
	
	mov [rect].bottom, edx
	add [rect].bottom, CarSize
	dec [rect].bottom
	
	invoke FillRect, [hdc], addr [rect], [color]
	ret
DrawCar endp

DrawFild proc
	local gameFild : dword 
	local i : dword 
	local j : dword
	local drawPosX : dword
	local drawPosY : dword
	

	local playerCar : HBRUSH
	local enemyCar : HBRUSH
	local colorBrush : COLORREF

	mov [colorBrush], RGB(89, 35, 87)
	invoke CreateSolidBrush, [colorBrush]
	mov [playerCar], eax

	mov [colorBrush], RGB(127, 107, 34)
	invoke CreateSolidBrush, [colorBrush]
	mov [enemyCar], eax
	
	invoke GetGameFild
	mov [gameFild], eax

	mov [i], 0
	mov [j], 0
	mov [drawPosX], 0
	mov [drawPosY], 0

	mov esi, ROAD_COUNT
	
	mov edx, ROAD_SIZE

	mov edi, [gameFild]

	.while [i] < ROAD_SIZE
		mov [j], 0
		.while [j] < ROAD_COUNT
			mov ecx, [edi].Car.cellType
			.if ecx == CAR_PLAYER
				push edi 
				invoke DrawCar, drawPosX, drawPosY, playerCar
				pop edi
			.elseif ecx == CAR_ENEMY
				push edi 
				invoke DrawCar, drawPosX, drawPosY, enemyCar
				pop edi
			.endif

			add edi, sizeof(Car)
			add [drawPosX], CarSize
			add [drawPosX], 10
			inc [j]
		.endw
		mov [drawPosX], 0
		add [drawPosY], CarSize
		inc [i]
	.endw

	ret 
DrawFild endp

end