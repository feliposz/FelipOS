%include 'felipos.inc'

main:
    call os_hide_cursor

    mov byte [row], 12
    mov byte [col], 40

.loop:
    mov dh, [row]
    mov dl, [col]
    call os_move_cursor
    mov si, guy
    call os_print_string

    call os_wait_for_key

    cmp al, 27
    je .end

    mov dh, [row]
    mov dl, [col]
    call os_move_cursor
    mov si, blank
    call os_print_string

    cmp ah, 48h
    je .up
    cmp ah, 4bh
    je .left
    cmp ah, 4dh
    je .right
    cmp ah, 50h
    je .down

    jmp .loop

.up:
    dec byte [row]
    jmp .loop
.down:
    inc byte [row]
    jmp .loop
.left:
    dec byte [col]
    jmp .loop
.right:
    inc byte [col]
    jmp .loop    

.end:
    call os_show_cursor
    call os_print_newline
    ret

guy   db 2, 0
blank db ' ', 0
row   db 0
col   db 0
