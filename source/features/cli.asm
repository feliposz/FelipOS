os_command_line:
    call os_clear_screen

get_command:
    mov si, prompt
    call os_print_string

    mov ax, input
    mov bx, 78
    call os_input_string
    call os_print_newline

    mov ax, input
    call os_string_uppercase

    mov si, input
    mov di, cls
    call os_string_compare
    jc cmd_cls

    mov si, input
    mov di, help
    call os_string_compare
    jc cmd_help

    mov si, input
    mov di, exit
    call os_string_compare
    jc cmd_exit

    mov cl, 5
    mov si, input
    mov di, echo
    call os_string_strincmp
    jc cmd_echo

    mov si, unknown_msg
    call os_print_string

    jmp get_command

cmd_exit:
    ret

cmd_cls:
    call os_clear_screen
    jmp get_command

cmd_help:
    mov si, help_msg
    call os_print_string
    jmp get_command

cmd_echo:
    mov ax, input
    call os_string_lowercase ; just for testing
    mov si, input
    add si, 5
    call os_print_string
    call os_print_newline
    jmp get_command

echo        db 'ECHO '
exit        db 'EXIT', 0
cls         db 'CLS', 0
help        db 'HELP', 0
help_msg    db 'Commands: HELP, CLS, ECHO, EXIT', 13, 10, 0
unknown_msg db 'Unknown command', 13, 10, 0
prompt      db '>', 0
input       times 79 db 0
