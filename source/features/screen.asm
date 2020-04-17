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
