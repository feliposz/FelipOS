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
