%include 'felipos.inc'

main:
    or si, si
    jz .no_args
    call os_string_to_int
    jmp .wait

.no_args:
    mov ax, 1

.wait:
    push ax
    mov si, sleep_msg
    call os_print_string
    call os_int_to_string
    mov si, ax
    call os_print_string
    call os_print_newline

    pop ax
    mov bl, 9 ; 1000 ms / 110 ms = 9 approx.
    mul bl
    call os_pause

    ret

sleep_msg db 'Sleeping for ', 0