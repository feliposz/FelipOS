%include 'felipos.inc'

main:
    mov ax, 1
    call os_serial_port_enable

    mov si, help_msg
    call os_print_string

.loop:
    call os_check_for_key
    cmp al, 27  ; ESCAPE
    je .exit

    call os_get_via_serial
    test ah, 10000000b
    jnz .error

    or al, al
    jz .loop

    mov si, output
    mov [si], al
    call os_print_string
    jmp .loop

.error:
    mov dx, 0
    mov ah, 3      ; check serial port status
    int 14h
    cmp ax, 060b0h ; timeout?
    je .loop

    call os_dump_registers
    mov si, error_msg
    call os_print_string

.exit:
    ret

help_msg   db 'Receiving data from serial port. Press ESC to exit.', 13, 10, 0
error_msg  db 'Get serial error.', 13, 10, 0
output     db ' ', 0
