; os_string_strincmp -- See if two strings match up to set number of chars
; IN: SI = string one, DI = string two, CL = chars to check
; OUT: carry set if same, clear if different
os_string_strincmp:
    pusha
    cld
.loop:
    jz .equal
    mov al, [si]
    cmpsb
    jne .not_equal
    or al, al
    jz .equal
    loop .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different
os_string_compare:
    pusha
    cld
.loop:
    mov al, [si]
    cmpsb
    jne .not_equal
    or al, al
    jnz .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

; os_string_uppercase -- Convert zero-terminated string to upper case
; IN/OUT: AX = string location
os_string_uppercase:
    pusha
    mov si, ax
.loop:
    mov al, [si]
    or al, al
    jz .done
    cmp al, 'a'
    jl .skip
    cmp al, 'z'
    jg .skip
    sub ax, 'a' - 'A'
    mov [si], al
.skip:
    inc si
    jmp .loop
.done:
    popa
    ret

; os_string_lowercase -- Convert zero-terminated string to lower case
; IN/OUT: AX = string location
os_string_lowercase:
    pusha
    mov si, ax
.loop:
    mov al, [si]
    or al, al
    jz .done
    cmp al, 'A'
    jl .skip
    cmp al, 'Z'
    jg .skip
    add al, 'a' - 'A'
    mov [si], al
.skip:
    inc si
    jmp .loop
.done:
    popa
    ret