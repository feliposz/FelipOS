%include 'felipos.inc'

main:
    or si, si
    jz .no_name
    mov ax, si
    jmp .message
.no_name:
    mov ax, name

.message:
    mov si, hello
    call os_print_string
    mov si, ax
    call os_print_string
    mov si, end
    call os_print_string
    ret

hello db 'Hello ', 0
name  db 'FelipOS', 0 
end   db '!!!', 13, 10, 0
