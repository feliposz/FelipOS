%include 'felipos.inc'

main:
    mov ax, 1
    call os_serial_port_enable

    mov si, help_msg
    call os_print_string

.loop:
    call os_wait_for_key
    cmp al, 27
    je .exit

    mov si, output
    mov [si], al
    call os_print_string

    call os_send_via_serial
    test ah, 10000000b
    jnz .error

    jmp .loop

.error:
    mov si, error_msg
    call os_print_string

.exit:
    ret

help_msg   db 'Sending data to serial port. Press ESC to exit.', 13, 10, 0
error_msg  db 'Send serial error.', 13, 10, 0
output     db ' ', 0