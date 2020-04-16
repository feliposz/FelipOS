; dummy kernel for bootload test
bits 16

    mov al, 'o'
    mov ah, 0x0e
    int 0x10
    mov al, 'k'
    mov ah, 0x0e
    int 0x10
    jmp $
