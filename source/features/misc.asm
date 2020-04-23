; ==========================================================
; os_get_api_version -- Return current version of MikeOS API
; IN: Nothing
; OUT: AL = API version number
os_get_api_version:
    mov al, API_VERSION
    ret

; ==========================================================
; os_pause -- Delay execution for specified 110ms chunks
; IN: AX = 100 millisecond chunks to wait (max delay is 32767, which multiplied by 55ms = 1802 seconds = 30 minutes)
os_pause:
    push ax
    push bx
    push cx
    push dx
    push si
    mov bx, ax
    shl bx, 1   ; counter * 2
    mov ah, 0   ; get ticks (increases every 55ms), result in CX:DX
    int 1ah     ; RTC bios service
    mov si, dx  ; save start tick count (only low word)
.wait:
    mov ah, 0
    int 1ah
    sub dx, si  ; how many ticks elapsed?
    cmp dx, bx
    jae .done
    jmp .wait
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
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
