os_command_line:
    call os_clear_screen
    jmp cmd_ver

get_command:
    mov si, prompt
    call os_print_string

    mov word [param_list], 0

    mov ax, input
    mov bx, 78
    call os_input_string
    call os_print_newline

    mov ax, input
    call os_string_chomp

    cmp byte [input], 0 ; empty command?
    je get_command

    mov si, input
    mov al, ' '
    call os_string_tokenize

    or di, di
    jz .no_params
    mov [param_list], di
    dec di
    mov byte [di], 0
.no_params:

    mov ax, input
    call os_string_uppercase

    mov si, input
    mov di, cls
    call os_string_compare
    jc cmd_cls

    mov si, input
    mov di, ver
    call os_string_compare
    jc cmd_ver

    mov si, input
    mov di, help
    call os_string_compare
    jc cmd_help

    mov si, input
    mov di, exit
    call os_string_compare
    jc cmd_exit

    mov si, input
    mov di, echo
    call os_string_compare
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

cmd_ver:
    mov si, version_msg
    call os_print_string
    jmp get_command

cmd_echo:
    mov si, [param_list]
    or si, si
    jz .no_params
    call os_print_string
.no_params:
    call os_print_newline
    jmp get_command

echo        db 'ECHO', 0
exit        db 'EXIT', 0
cls         db 'CLS', 0
ver         db 'VER', 0
help        db 'HELP', 0
help_msg    db 'Commands: HELP, CLS, ECHO, VER, EXIT', 13, 10, 0
unknown_msg db 'Unknown command', 13, 10, 0
version_msg db 'FelipOS ', OS_VERSION, 13, 10, 0
prompt      db '>', 0
param_list  dw 0
input       times 79 db 0
