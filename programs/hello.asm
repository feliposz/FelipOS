bits 16
org 32768

start:
    mov si, hello
    mov ah, 0eh
.loop
    lodsb
    or al, al
    jz .end
    int 10h
    jmp .loop
.end:
    ret

hello db 'Hello FelipOS!', 13, 10, 0
