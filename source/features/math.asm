; os_bcd_to_int -- Converts binary coded decimal number to an integer
; IN: AL = BCD number
; OUT: AX = integer value
os_bcd_to_int:
    push bx
    push cx
    mov bx, ax
    and bx, 0fh ; keep low digit
    shr al, 4
    mov cl, 10  ; high digit * 10
    mul cl
    add ax, bx  ; high + low
    pop cx
    pop bx
    ret

; os_long_int_negate -- Multiply value in DX:AX by -1
; IN: DX:AX = long integer
; OUT: DX:AX = -(initial DX:AX)
os_long_int_negate:
    neg ax
    adc dx, 0
    neg dx
    ret

; os_seed_random -- Seed the random number generator based on clock
; IN: Nothing
; OUT: Nothing (registers preserved)
os_seed_random:
    push ax
    push bx
    push cx
    push dx
.retry:
    mov ah, 2   ; get system time
    int 1ah
    jc .retry

    ; CH = hours in BCD
    ; CL = minutes in BCD
    ; DH = seconds in BCD
    ; DL = 1 if daylight savings time option

    mov al, dh
    call os_bcd_to_int
    mov bx, ax

    mov al, cl
    call os_bcd_to_int
    mov dx, 60
    mul dx
    add bx, ax

    mov al, ch
    call os_bcd_to_int
    mov dx, 3600
    mul dx
    add bx, ax

    mov [random_seed], bx

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer
os_get_random:
    push ax
    push bx
    push dx
    sub bx, ax
    mov cx, 29571
    mov ax, [random_seed]
    mul cx
    inc ax
    mov [random_seed], ax
    xor dx, dx
    div bx
    mov cx, dx
    pop dx
    pop bx
    pop ax
    add cx, ax
    ret

random_seed dw 0