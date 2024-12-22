; Program: DOS VGA Paint
; Description:
;   This program sets the display mode to 320x200x256 (VGA mode 13h),
;   clears the screen to white, and initializes the mouse.
;   The user can move the mouse and click to draw pixels on the screen.
;   The user can also change the drawing color using keyboard keys,
;   clear the screen, or quit the program.
;
; Controls:
;   '1' = Set drawing color to Red
;   '2' = Set drawing color to Green
;   '3' = Set drawing color to Blue
;   '4' = Set drawing color to Black
;   '5' = Set drawing color to White
;   'c' = Clear screen (restore to white)
;   'q' = Quit the program
;
; Default drawing color: Black
; Drawing is done by left-clicking the mouse.
; The mouse pointer is managed by the system mouse driver.

.MODEL TINY
.STACK 64

.DATA
color_selected DB 00H   ; Current drawing color (default: black)

.CODE
ORG 100H

Start:
    ; Initialize registers
    XOR AX, AX
    XOR BX, BX
    XOR CX, CX
    XOR DX, DX

    ; Enter VGA mode 13h (320x200x256)
    MOV AH, 00H
    MOV AL, 0DH
    INT 10H

    ; Clear the screen to white
    MOV CX, 0
    MOV DX, 0
    CALL ClearScreenWhite

    ; Initialize mouse driver
    MOV AX, 0000H
    INT 33H
    ; Show mouse pointer
    MOV AX, 0001H
    INT 33H

    ; Set mouse horizontal range (0 to 640)
    ; The mouse driver often returns a coordinate system double the width (640 vs 320).
    MOV AX, 0007H
    MOV CX, 0
    MOV DX, 640
    INT 33H

    ; Set mouse vertical range (0 to 199)
    MOV AX, 0008H
    MOV CX, 0
    MOV DX, 199
    INT 33H

    ; Ensure the initial drawing color is black
    CALL SetBlack

MainLoop:
    ; Check if a key is pressed
    MOV AH, 01H
    INT 16H
    JZ CheckMouse  ; If no key, check mouse events

    ; A key is pressed; read it
    MOV AH, 00H
    INT 16H

    ; Compare the pressed key and set actions accordingly
    CMP AL, '1'
    JE SetRed
    CMP AL, '2'
    JE SetGreen
    CMP AL, '3'
    JE SetBlue
    CMP AL, '4'
    JE SetBlack
    CMP AL, '5'
    JE SetWhite
    CMP AL, 'c'
    JE ClearToWhite
    CMP AL, 'q'
    JE QuitProgram

    JMP MainLoop

SetRed:
    ; Set color to red (04h)
    MOV [color_selected], 04H
    JMP MainLoop

SetGreen:
    ; Set color to green (02h)
    MOV [color_selected], 02H
    JMP MainLoop

SetBlue:
    ; Set color to blue (01h)
    MOV [color_selected], 01H
    JMP MainLoop

SetBlack:
    ; Set color to black (00h)
    MOV [color_selected], 00H
    JMP MainLoop

SetWhite:
    ; Set color to white (0Fh)
    MOV [color_selected], 0FH
    JMP MainLoop

ClearToWhite:
    ; Clear the screen back to white
    MOV CX, 0
    MOV DX, 0
    CALL ClearScreenWhite
    JMP MainLoop

CheckMouse:
    ; Read mouse position and button status
    MOV AX, 0003H
    INT 33H

    ; If left button not pressed, return to main loop
    TEST BX, 0001B
    JZ MainLoop

    ; Adjust X coordinate since mouse returns a wider range
    ; Halve it to fit the 320-width resolution of mode 13h
    MOV AX, CX
    SHR AX, 1
    MOV CX, AX

    ; Slight offset adjustments
    SUB CX, 1
    SUB DX, 1

    ; Draw pixel at (CX, DX) with current color
    CALL DrawPixel
    JMP MainLoop

DrawPixel PROC
    ; AH=0Ch: Write pixel in graphics mode
    MOV AH, 0CH
    MOV AL, [color_selected]
    INT 10H
    RET
DrawPixel ENDP

ClearScreenWhite PROC
    ; Fill entire 320x200 screen with white (0Fh)
    MOV AL, 0FH
    MOV AH, 0CH
    MOV DX, 0
    MOV CX, 0

FillRows:
    INT 10H
    INC CX
    CMP CX, 320
    JGE NextRow
    JMP FillRows

NextRow:
    INC DX
    MOV CX, 0
    CMP DX, 200
    JGE DoneFilling
    JMP FillRows

DoneFilling:
    RET
ClearScreenWhite ENDP

QuitProgram:
    ; Restore text mode (80x25)
    MOV AH, 00H
    MOV AL, 03H
    INT 10H

    ; Exit to DOS
    MOV AX, 4C00H
    INT 21H

END Start
