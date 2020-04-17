os_command_line:
    call os_clear_screen

get_command:
    mov si, prompt
    call os_print_string

    mov ax, input
    mov bx, 78
    call os_input_string

    call os_print_newline

    ; echo input for testing
    mov si, input
    call os_print_string

    call os_print_newline

    jmp get_command

    ret

prompt db '>', 0
input times 79 db 0