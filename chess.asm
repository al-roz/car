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

CreateWindowA proto lpClassName:LPCTSTR, lpWindowName:LPCTSTR, dwStyle:dword, x:dword, y:dword, nWidth:dword, nHeight:dword, hWndParent:HWND, hMenu:HMENU, hInstance:HINSTANCE, lpParam:LPVOID
IFNDEF __UNICODE__
  CreateWindow equ <CreateWindowA>
ENDIF

include chess.inc
include Strings.mac

;----------------------------------------

ChessWindowName equ <"ChessWindow">

CHESS_WIDTH   equ   40
CHESS_HEIGHT  equ   CHESS_WIDTH
CHESS_CENTER  equ   (CHESS_WIDTH/2)


ChessWindowStruct struct
    color   COLORREF    ?
    ftype   FIGTYPE     ?
ChessWindowStruct ends

;----------------------------------------

CreateChessRgn proto hIns:HINSTANCE

MoveChessByCenter proto hwnd:HWND, x:dword, y:dword

GetChessCenter proto hwnd:HWND, x:ptr dword, y:ptr dword

WndProcChess proto stdcall hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

;----------------------------------------

.data

.data?
glPawnRgn   HRGN ?
glCastleRgn HRGN ?
glBishopRgn HRGN ?
glKnightRgn HRGN ?
glQueenRgn  HRGN ?
glKingRgn   HRGN ?

glImages    HIMAGELIST ?
glImages2   HIMAGELIST ?

;----------------------------------------
.code

;
;
RegisterClassChessWindow proc hIns:HINSTANCE

    local WndClass:WNDCLASSEX	
    
    invoke CreateChessRgn, hIns

    
    mov WndClass.cbSize, sizeof (WNDCLASSEX)    
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcChess      ; ????? ??????? ????????? ??????
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, sizeof(dword)        
    mov eax, [hIns]
    mov WndClass.hInstance, eax                 ; ????????? ??????????
    mov WndClass.hIcon, NULL
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    mov WndClass.hbrBackground, NULL
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(ChessWindowName)	; ??? ??????
    mov WndClass.hIconSm, NULL

    invoke RegisterClassEx, addr WndClass
    ret

RegisterClassChessWindow endp

;--------------------

CreateChessRgn proc uses edi esi hIns:HINSTANCE

    local   hb:HBITMAP
    local   dstRgn:HRGN
    local   tmpRgn:HRGN
    local   bitmap:BITMAP
    local   bmih:BITMAPINFOHEADER
    local   i:dword
    local   j:dword
    local   bits:ptr dword
    local   left:dword
    local   right:dword
    local   pattern:dword
    local   bmWidth:dword
    local   hdc:HDC
    local   fig:dword
    ;static char *names[] = {"Pawn", "Castle", "Bishop", "Knight", "Queen", "King"};
    ;static HRGN *rgns[] = {&glPawnRgn, &glCastleRgn, &glBishopRgn, &glKnightRgn, &glQueenRgn, &glKingRgn};
    local   rgns[6]:HRGN
    
INVALID_OFFSET  equ     0
SIZE_FIG        equ     40
    
    mov eax, offset glPawnRgn
    mov rgns[0*sizeof(HRGN)], eax
    mov eax, offset glCastleRgn
    mov rgns[1*sizeof(HRGN)], eax
    mov eax, offset glBishopRgn
    mov rgns[2*sizeof(HRGN)], eax
    mov eax, offset glKnightRgn
    mov rgns[3*sizeof(HRGN)], eax
    mov eax, offset glQueenRgn
    mov rgns[4*sizeof(HRGN)], eax
    mov eax, offset glKingRgn
    mov rgns[5*sizeof(HRGN)], eax
    
    invoke crt_malloc, 4 * 480 * 40;
    mov [bits], eax
    
    ; ????????? ???????? ?? ????????
    invoke LoadBitmap, [hIns], $CTA0("Fig")
    mov [hb], eax

    ; ???????? ?????????? ? ???????? ? ?????????
    invoke GetObject, [hb], sizeof(BITMAP), addr bitmap
    
    ; ???????? ???????? ??????????
    invoke GetDC, NULL
    mov [hdc], eax
    
    ; ????????? ???? ????????? ??? ????????? ????????? ???????
    mov [bmih].biSize, sizeof (BITMAPINFOHEADER)
    mov eax, [bitmap].bmWidth
    mov [bmih].biWidth, eax
    mov eax, [bitmap].bmHeight
    mov [bmih].biHeight, eax
    mov ax, [bitmap].bmPlanes
    mov [bmih].biPlanes, ax
    mov ax, [bitmap].bmBitsPixel
    mov [bmih].biBitCount, ax
    mov [bmih].biClrUsed, 0
    mov [bmih].biCompression, BI_RGB
    mov [bmih].biSizeImage, 0
    mov [bmih].biClrImportant, 0
    
    ;???????? ???????? ? ???? ??????? ????
    invoke GetDIBits, [hdc], [hb], 0, [bitmap].bmHeight, [bits], addr bmih, DIB_RGB_COLORS
    .if !eax
        ret
    .endif
    
    invoke ReleaseDC, NULL, [hdc]
    
    ; ????? ??????? ???? ?????????? ? ???????? ???????
    ; ??? ??????????? ???????, ??????? ????? ???????????
    mov eax, [bits]
    mov eax, [eax]
    mov [pattern], eax
    
    mov eax, [bitmap].bmWidth
    mov [bmWidth], eax
    
    mov [fig], 0
    .while [fig] < 6
        
        invoke CreateRectRgn, 0, 0, 0, 0
        mov [dstRgn], eax
        
        mov [i], 0
        
        mov esi, [bitmap].bmHeight
        .while [i] < esi
        
            mov [left], INVALID_OFFSET
            mov [right], INVALID_OFFSET
            
            mov eax, [fig]
            imul eax, SIZE_FIG
            mov [j], eax
            add eax, SIZE_FIG
            mov esi, eax
            .while [j] < esi
            
                mov eax, [bitmap].bmWidth
                imul eax, [i]
                add eax, [j]
                mov ecx, [bits]
                mov eax, [ecx+eax*4]
                .if [pattern] == eax
                    .if [left] == INVALID_OFFSET
                        inc [j]
                        .continue
                    .else
                        .if [right] == INVALID_OFFSET
                            mov eax, [fig]
                            imul eax, SIZE_FIG
                            mov ecx, [j]
                            sub ecx, eax
                            dec ecx
                            mov [right], ecx
                        .else
                            ; ???? ????? ????? ? ?????? ??????????
                            
                            ; ??????? ?????? ??????? ? 1 ??????
                            mov eax, SIZE_FIG
                            sub eax, [i]
                            mov ecx, eax
                            dec eax
                            invoke CreateRectRgn, [left], eax, [right], ecx
                            mov [tmpRgn], eax
                            
                            ; ??????????? ? ??? ????????????? ?????????
                            invoke CombineRgn, dstRgn, [dstRgn], [tmpRgn], RGN_OR
                            mov [left], INVALID_OFFSET
                            mov [right], INVALID_OFFSET
                            invoke DeleteObject, [tmpRgn]
                        .endif
                    .endif
                .else
                    .if [left] == INVALID_OFFSET
                        mov eax, [fig]
                        imul eax, SIZE_FIG
                        mov ecx, [j]
                        sub ecx, eax
                        mov [left], ecx
                    .endif
                .endif
                
                inc [j]
                
                mov eax, [fig]
                inc eax
                imul eax, SIZE_FIG
                mov esi, eax
            .endw
            
            ; ????????? ? ?????? ?????? ????????? ?????
            mov eax, SIZE_FIG
            sub eax, [i]
            mov ecx, eax
            dec eax
            invoke CreateRectRgn, [left], eax, [right], ecx
            mov [tmpRgn], eax
            
            ; ??????????? ? ??? ????????????? ?????????
            invoke CombineRgn, dstRgn, [dstRgn], [tmpRgn], RGN_OR
            mov [left], INVALID_OFFSET
            mov [right], INVALID_OFFSET
            invoke DeleteObject, [tmpRgn]
            
            mov esi, [bitmap].bmHeight
            inc [i]
        .endw
        
        mov ecx, [fig]
        mov ecx, rgns[ecx * sizeof(HRGN)]
        mov eax, [dstRgn]
        mov [ecx], eax
        
        inc [fig]
    .endw

    mov eax, 1
    ret

CreateChessRgn endp

;--------------------

CreateChessWindow proc hIns:HINSTANCE, parent:HWND, color:COLORREF, x:dword, y:dword, ftype: FIGTYPE

    local hwnd:HWND     ; ????????? ????
    local rgn:HRGN      ; ????????? ???????

    .if ftype > FIG_MAX || ftype == FIG_NULL
        xor eax, eax
        ret
    .endif
    
    invoke RegisterClassChessWindow, hIns
    
    invoke CreateWindowEx, 0, $CTA0(ChessWindowName), NULL, WS_OVERLAPPED or WS_CHILD, 0, 0, 0, 0, parent, NULL, hIns, NULL
    mov [hwnd], eax
    .if ![hwnd]
        xor eax, eax
        ret
    .endif
    
    invoke GetWindowLong, [hwnd], 0
    mov ecx, [ftype]
    mov [eax].ChessWindowStruct.ftype, ecx
    mov ecx, [color]
    mov [eax].ChessWindowStruct.color, ecx
    
    invoke MoveChessByCenter, [hwnd], [x], [y]
    
    .if ftype == FIG_PAWN
        mov eax, glPawnRgn
        mov [rgn], eax
    .elseif ftype == FIG_CASTLE
        mov eax, glCastleRgn
        mov [rgn], eax
    .elseif ftype == FIG_KNIGHT
        mov eax, glKnightRgn
        mov [rgn], eax
    .elseif ftype == FIG_BISHOP
        mov eax, glBishopRgn
        mov [rgn], eax
    .elseif ftype == FIG_QUEEN
        mov eax, glQueenRgn
        mov [rgn], eax
    .elseif ftype == FIG_KING
        mov eax, glKingRgn
        mov [rgn], eax
    .endif
    
    invoke SetWindowRgn, [hwnd], [rgn], FALSE
    
    invoke ShowWindow, [hwnd], SW_SHOWNORMAL
    invoke UpdateWindow, [hwnd]

    mov eax, [hwnd]
    ret

CreateChessWindow endp

;--------------------

MoveChessByCenter proc hwnd:HWND, x:dword, y:dword

    sub [x], CHESS_CENTER
    sub [y], CHESS_CENTER
    invoke MoveWindow, [hwnd], [x], [y], CHESS_WIDTH, CHESS_HEIGHT, TRUE
    
    invoke crt_printf, $CTA0("%08x %d %d\n"), [hwnd], [x], [y]
    
    ret

MoveChessByCenter endp

;--------------------

GetChessCenter proc hwnd:HWND, x:ptr dword, y:ptr dword

    local rect:RECT
    local parent:HWND
    local point:POINT
    
    
    invoke GetWindowRect, [hwnd], addr rect
    
    
    mov eax, [rect].left
    mov [point].x, eax
    add [point].x, CHESS_WIDTH/2
    mov eax, [rect].top
    mov [point].y, eax
    add [point].y, CHESS_HEIGHT/2

    
    invoke GetParent, [hwnd]
    mov [parent], eax
    
    
    invoke ScreenToClient, [parent], addr point
    
    
    mov ecx, [x]
    mov eax, [point].x
    mov [ecx], eax
    mov ecx, [y]
    mov eax, [point].y
    mov [ecx], eax
    
    ret

GetChessCenter endp

;--------------------

WndProcChess proc stdcall hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local ps:PAINTSTRUCT
    local list:HIMAGELIST
    local brush:HBRUSH
    local cws:ptr ChessWindowStruct
    local rect:RECT
    local x:dword
    local y:dword
    local center_x:dword
    local center_y:dword
    
    invoke GetWindowLong, [hwnd], 0
    mov [cws], eax
    
    .if [iMsg] == WM_CREATE
        
       
        invoke crt_malloc, sizeof(ChessWindowStruct)
        mov [cws], eax
        .if ![cws]
            mov eax, -1
            ret
        .endif
        
       
        invoke SetWindowLong, [hwnd], 0, [cws]
        
        xor eax, eax
        ret
        
    .elseif [iMsg] == WM_DESTROY
    
        xor eax, eax
        ret
        
    .elseif [iMsg] == WM_PAINT
    
        invoke BeginPaint, [hwnd], addr ps
        mov [hdc], eax
        mov eax, [cws]
        .if [eax].ChessWindowStruct.color == COLOR_WHITE
            mov eax, [glImages2]
            mov list, eax
        .else
            mov eax, [glImages]
            mov list, eax
        .endif
        
        invoke EndPaint, [hwnd], addr ps
        
        xor eax, eax
        ret
    
    
    .elseif [iMsg] == WM_ERASEBKGND
    
    
        mov eax, [wParam]
        mov [hdc], eax

    
        mov eax, [cws]
        invoke CreateSolidBrush, [eax].ChessWindowStruct.color
        mov [brush], eax
        
    
        mov [rect].left, 0
        mov [rect].top, 0
        mov [rect].right, CHESS_WIDTH
        mov [rect].bottom, CHESS_HEIGHT
        invoke FillRect, [hdc], addr rect, [brush]
        
        xor eax, eax
        ret
    
    .elseif [iMsg] == WM_LBUTTONDOWN
        invoke SetCapture, [hwnd]
        
        invoke InvalidateRect, [hwnd], NULL, TRUE
        
        xor eax, eax
        ret
    
    .elseif [iMsg] == WM_LBUTTONUP
    
        invoke ReleaseCapture


        
        xor eax, eax
        ret
        
    .elseif [iMsg] == WM_MOUSEMOVE
    
        .if [wParam] & MK_LBUTTON
             
            movsx eax, word ptr [lParam]
            mov [x], eax
            movsx eax, word ptr [lParam+2]
            mov [y], eax
       
            invoke GetChessCenter, [hwnd], addr center_x, addr center_y
       
            mov eax, [x]
            sub eax, CHESS_CENTER
            add [center_x], eax
            mov eax, [y]
            sub eax, CHESS_CENTER
            add [center_y], eax
            invoke MoveChessByCenter, [hwnd], [center_x], [center_y]
            
        .endif
    
        xor eax, eax
        ret
        
    .endif

    invoke DefWindowProc, [hwnd], [iMsg], [wParam], [lParam]
    ret
    
WndProcChess endp

;--------------------

end
