bits 16

    jmp kernel_start

    %define OS_VERSION '0.0.1'
    %define API_VERSION 17

kernel_start:

    ; setup segments and stack pointer
    cli
    mov ax, cs
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0ffffh
    sti

kernel_main:

    ; start CLI
    call os_command_line

    mov si, end_msg
    call os_print_string

    ; halt
    jmp $

    %include 'features/cli.asm'
    %include 'features/screen.asm'
    %include 'features/string.asm'

end_msg db 'Exited', 13, 10, 0
