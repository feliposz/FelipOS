; ==========================================================
; os_get_api_version -- Return current version of MikeOS API
; IN: Nothing
; OUT: AL = API version number
os_get_api_version:
    mov al, API_VERSION
    ret

; ==========================================================
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location
os_fatal_error:
    push si
    call os_print_newline
    mov si, ax
    call os_print_string
    call os_print_newline
    pop si
    call os_dump_registers
.halt:
    hlt
    jmp .halt
