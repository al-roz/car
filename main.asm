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

include Strings.mac
include CarView.inc
include CarModel.inc
;include chess.inc


RGB macro r:REQ, g:REQ, b:REQ
	tmp = (r) or ((g) shl 8) or ((b) shl 16)
	%echo @CatStr(%tmp)
    exitm <tmp>
endm

;----------------------------------------

FILE struct
    _ptr    DWORD       ?
    _cnt    DWORD       ?
    _base   DWORD       ?
    _flag   DWORD       ?
    _file   DWORD       ?
    _charbuf DWORD      ?
    _bufsiz DWORD       ?
    _tmpfname DWORD     ?
FILE ends

__iob_func proto c

_O_TEXT equ 4000h

_IONBF  equ 0004h

TIMER_1 equ 200

TIMER_SPEAD equ 350

;----------------------------------------

;----------------------------------------


AppWindowName equ <"Application">

;----------------------------------------


.data

.data?

hIns HINSTANCE ?

HwndMainWindow HWND ?

.const

.code

;----------------------------------------

RegisterClassMainWindow proto;

CreateMainWindow proto;

WndProcMain proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

;----------------------------------------

;
;
CreateExtraConsole proc stdcall

    local stdin:DWORD
    local stdout:DWORD
    local stderr:DWORD

    invoke AllocConsole
    .if eax == 0
        ret
    .endif

    invoke __iob_func
    mov [stdin], eax
    add eax, sizeof (FILE)
    mov [stdout], eax
    add eax, sizeof (FILE)
    mov [stderr], eax
    
    invoke SetConsoleTitle, $CTA0("Debug console")
    
    invoke GetStdHandle, STD_INPUT_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("r\0")
    invoke crt_memcpy, [stdin], eax, sizeof (FILE)
    
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("w\0")
    invoke crt_memcpy, [stdout], eax, sizeof (FILE)
    
    invoke GetStdHandle, STD_ERROR_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("w\0")
    invoke crt_memcpy, [stderr], eax, sizeof (FILE)
    
    invoke crt_setvbuf, [stdout], NULL, _IONBF, 0
    .if eax
        xor eax, eax
        ret
    .endif
    
    invoke crt_setvbuf, [stderr], NULL, _IONBF, 0
    .if eax
        xor eax, eax
        ret
    .endif
    
    mov eax, 1
    ret

CreateExtraConsole endp

;--------------------

WinMain proc stdcall hInstance:HINSTANCE, hPrevInstance:HINSTANCE, szCmdLine:PSTR, iCmdShow:DWORD

    local msg: MSG
	local i : dword 

    mov eax, [hInstance]
    mov [hIns], eax

    invoke CreateExtraConsole
    invoke crt_printf, $CTA("Hello, World\n\0")

    invoke CreateMainWindow
    mov [HwndMainWindow], eax
    .if [HwndMainWindow] == 0
        xor eax, eax
        ret
    .endif
	
	invoke SetTimer, [HwndMainWindow], TIMER_1, TIMER_SPEAD, NULL

    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
            .break .if eax == 0

        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg

    .endw

    mov eax, [msg].wParam
    ret

WinMain endp

;--------------------

;

;
RegisterClassMainWindow proc

    local WndClass:WNDCLASSEX	


    mov WndClass.cbSize, sizeof (WNDCLASSEX)	
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcMain		
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 4
    mov eax, [hIns]
    mov WndClass.hInstance, eax					
    invoke LoadIcon, hIns, $CTA0("MainIcon")	
    mov WndClass.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    invoke GetStockObject, WHITE_BRUSH			
    mov WndClass.hbrBackground, eax
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(AppWindowName)
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIconSm, eax

    invoke RegisterClassEx, addr WndClass
    ret

RegisterClassMainWindow endp

;--------------------

;

;
CreateMainWindow proc

    local hwnd:HWND
	
    invoke RegisterClassMainWindow

    invoke CreateWindowEx, 
        WS_EX_CONTROLPARENT or WS_EX_APPWINDOW, 
        $CTA0(AppWindowName),	
        $CTA0("Application"),	
        WS_OVERLAPPEDWINDOW,	
        10,	    
        10,	    
        650,    
        650,    
        NULL,   
        NULL,   
        [hIns], 
        NULL
    mov [hwnd], eax
    
    .if [hwnd] == 0
        invoke MessageBox, NULL, $CTA0("jest"), NULL, MB_OK
        xor eax, eax
        ret
    .endif

	invoke SetHwndMainWindow, hwnd

    invoke InitGameModel, eax

	invoke SetWindowLong, hwnd, 0, eax

    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    
    mov eax, [hwnd]
    ret

CreateMainWindow endp

;--------------------
CheckOnGameOverAndEndGame proc
	local buf : dword
	invoke GetGameStatus
	.if eax == GAME_OVER
		invoke KillTimer, HwndMainWindow, TIMER_1
		invoke crt_calloc, 10, 1
		mov [buf], eax
		invoke GetScore
		invoke crt__itoa, eax, [buf], 10
		
		invoke MessageBox, NULL, eax, $CTA0("GAME OVER"), MB_OK
		invoke PostQuitMessage, 0
		xor eax, eax			
		ret
	.endif
	ret
CheckOnGameOverAndEndGame endp


WndProcMain proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
	local pen:HPEN
    local ps:PAINTSTRUCT
	local rect:RECT
	local x : dword
	local y : dword

    .if [iMsg] == WM_CREATE      		

		;invoke SetWindowLong, hwnd, 0, eax
	
		;invoke GetWindowLong, hwnd, 0		

        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_PAINT
        
        invoke BeginPaint, HwndMainWindow, addr ps
        mov [hdc], eax

		invoke SetHDC, [hdc]

		invoke GetClientRect, hwnd, addr rect

		invoke CreateGameRoad, addr [rect]
	
		invoke DrawFild
        
        invoke EndPaint, [hwnd], addr ps
        
        xor eax, eax
        ret	
	.elseif [iMsg] == WM_SIZE

		xor edx, edx
		mov eax, CarSize
		add eax, 10
		mov ebx, ROAD_COUNT
		imul eax, ebx
		sub eax, 10
		add eax, 16
		mov [x], eax
	
		xor edx, edx
		mov eax, CarSize
		mov ebx, ROAD_SIZE
		imul eax, ebx
		add eax, 39
		mov [y], eax
		invoke SetWindowPos, hwnd, NULL, 10, 10,[x],[y],0
		invoke InvalidateRect, hwnd, NULL, TRUE
		ret
	.elseif [iMsg] == WM_KEYDOWN
		.if wParam == VK_LEFT
			invoke MoveLeft
			invoke InvalidateRect, hwnd, NULL, TRUE
			invoke CheckOnGameOverAndEndGame
			ret
		.elseif wParam == VK_RIGHT
			invoke MoveRight 
			invoke InvalidateRect, hwnd, NULL, TRUE
			invoke CheckOnGameOverAndEndGame
			ret
		.elseif wParam == VK_UP
			invoke MoveUp
			invoke InvalidateRect, hwnd, NULL, TRUE
			invoke CheckOnGameOverAndEndGame
			ret
		.elseif wParam == VK_DOWN
			invoke MoveDown									
			invoke InvalidateRect, hwnd, NULL, TRUE
			invoke CheckOnGameOverAndEndGame
			ret
		.endif 
	.elseif [iMsg] == WM_TIMER
		invoke IncScore
		invoke MoveMatrixDown
		invoke ClearFirstLine 			
		invoke CreateEnemyLine
		invoke InvalidateRect, hwnd, NULL, TRUE
		invoke CheckOnGameOverAndEndGame
    .endif
   
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret

WndProcMain endp

;--------------------
;--------------------
;--------------------

end
