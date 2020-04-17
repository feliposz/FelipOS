bits 16

    jmp kernel_start

kernel_start:

    ; setup segments and stack pointer
    cli
    mov ax, cs
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, ffffh
    sti

kernel_main:

    ; start CLI
    call os_command_line

    ; halt
    jmp $

sys_bootdev db 0

    %include 'features/cli.asm'
    %include 'features/screen.asm'
