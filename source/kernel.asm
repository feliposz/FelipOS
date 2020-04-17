bits 16

    jmp kernel_start

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

end_msg db 'Exited', 13, 10, 0

    %include 'features/cli.asm'
    %include 'features/screen.asm'
    %include 'features/string.asm'
