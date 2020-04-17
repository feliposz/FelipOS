; ==========================================================
; os_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)
os_print_string:
    pusha
    mov ah, 0eh       ; print character
.loop:
    lodsb
    or al, al
    jz .done
    int 10h           ; bios video services
    jmp .loop
.done:
    popa
    ret

; ==========================================================
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)
os_clear_screen:
    pusha
    mov ax, 0600h     ; AH=06 scroll up, AL=00 clear
    mov bh, 07h       ; color (0 = black, 7 = gray)
    mov cx, 0         ; CH=0 top row, CL=0 left col
    mov dx, 184fh     ; DH=24 bottom row, DL=79 right col
    int 10h           ; bios video services
    mov ah, 02h       ; set cursor position
    mov bh, 0         ; page 0
    mov dx, 0         ; DH=0 top row, DL=0 left col
    int 10h
    popa
    ret

; ==========================================================
; os_print_newline -- Reset cursor to start of next line
; - IN/OUT: Nothing (registers preserved)
os_print_newline:
    pusha
    mov ah, 0eh
    mov al, 0dh       ; CR
    int 10h
    mov al, 0ah       ; LF
    int 10h
    popa
    ret

; ==========================================================
; os_input_string -- Get a string from keyboard input
; - IN: AX = output address, BX = maximum bytes of output string
; - OUT: nothing
os_input_string:
    pusha
    mov cx, 0
    mov di, ax
.loop:
    mov ah, 0         ; read character function (result in AL)
    int 16h          ; BIOS keyboard services

    cmp al, 08h      ; 08h is backspace
    je .backspace

    cmp al, 0dh      ; 0dh is carriage return (enter)
    je .done

    cmp cx, bx       ; ignore more characters after buffer limit
    je .loop

    mov ah, 0eh      ; print character at AL
    int 10h

    stosb             ; save character to buffer pointed by DI and advance DI
    inc cx            ; increment character count
    jmp .loop

.backspace:
    or cx, cx         ; if counter is zero, ignore backspace
    jz .loop

    dec di
    dec cx
    mov byte [di], 0  ; erase character at DI

    ; erase previous character on screen
    mov ah, 0eh      ; print character
    mov al, 08h      ; backspace (move back one character)
    int 10h
    mov al, ' '       ; space (erase)
    int 10h
    mov al, 08h      ; backspace again
    int 10h

    jmp .loop

.done:

    ; add NUL terminator to buffer
    mov al, 0
    stosb
    popa
    ret
