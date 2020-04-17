os_command_line:
    call os_clear_screen

    mov si, prompt
    call os_print_string

    ret

prompt db '>', 0
