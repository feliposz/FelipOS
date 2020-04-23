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

; ==========================================================
; os_print_digit -- Displays contents of AX as a single digit. Works up to base 37, ie digits 0-Z.
; IN: AX = "digit" to format and print
os_print_digit:
    push ax
    mov ah, 0eh
    cmp al, 9
    ja .not_digit
    add al, '0'
    jmp .done
.not_digit:
    add al, 'A' - 10
.done:
    int 10h
    pop ax
    ret

; ==========================================================
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print
os_print_1hex:
    push ax
    and ax, 000fh
    call os_print_digit
    pop ax
    ret

; ==========================================================
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print
os_print_2hex:
    push ax
    shr ax, 4
    and ax, 000fh
    call os_print_digit
    pop ax
    push ax
    and ax, 000fh
    call os_print_digit
    pop ax
    ret

; ==========================================================
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print
os_print_4hex:
    push ax
    push bx
    push cx
    mov bx, ax
    mov cx, 4
.next_nibble:
    rol bx, 4
    mov ax, bx
    and ax, 000fh
    call os_print_digit
    loop .next_nibble
    pop cx
    pop bx
    pop ax
    ret

; ==========================================================
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing
os_print_space:
    push ax
    mov ah, 0eh
    mov al, ' '
    int 10h
    pop ax
    ret

; ==========================================================
; os_dump_registers -- Displays register contents in hex on the screen
; IN/OUT: AX/BX/CX/DX = registers to show
os_dump_registers:
    pushf   ; sp + 12
    push es
    push ds
    push ss
    push cs
    push di
    push si
    push bp
    push dx
    push cx
    push bx
    push ax ; sp + 0

    mov si, .register_msg
    call os_print_string

    ; print the registers pushed on stack in the order given above + return address (IP)
    mov cx, 13
    mov si, sp
.dump_loop:
    lodsw
    call os_print_4hex
    call os_print_space
    loop .dump_loop

    ; print value of SP register before os_dump_registers call
    mov ax, sp
    add ax, 26 ; = 2 * (12 pushes above + return address)
    call os_print_4hex
    call os_print_newline

    pop ax
    pop bx
    pop cx
    pop dx
    pop bp
    pop si
    pop di

    popf ; dummy pop to avoid overwriting segments!
    popf
    popf 
    popf

    popf

    ret

.register_msg db 'AHAL BHBL CHCL DHDL BP   SI   DI   CS   SS   DS   ES   Flag IP   SP', 13, 10, 0

; ==========================================================
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column
; OUT: Nothing (registers preserved)
os_move_cursor:
    push ax
    push bx
    mov ah, 2
    mov bh, 0
    int 10h
    pop bx
    pop ax
    ret

; ==========================================================
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column
os_get_cursor_pos:
    push ax
    push bx
    push cx
    mov ah, 3
    mov bh, 0
    int 10h
    pop cx
    pop bx
    pop ax
    ret

; ==========================================================
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: Nothing
os_show_cursor:
    push ax
    push cx
    mov ah, 1     ; set cursor shape
    mov cx, 0607h ; lines 6-7 in "emulated" 8x8 mode
    int 10h
    pop cx
    pop ax
    ret

; ==========================================================
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: Nothing
os_hide_cursor:
    push ax
    push cx
    mov ah, 1     ; set cursor shape
    mov cx, 2000h ; no cursor
    int 10h
    pop cx
    pop ax
    ret


