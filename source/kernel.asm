bits 16

    %define OS_VERSION '0.0.1'
    %define API_VERSION 17

    disk_buffer equ 24576   ; 8k disk buffer located after OS code and before 32k (user space)

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

    call disk_init

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
    %include 'features/math.asm'
    %include 'features/disk.asm'

end_msg db 'Exited', 13, 10, 0
