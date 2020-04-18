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

; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location
os_string_chomp:
    pusha
    cld
    mov bx, ax
    mov si, ax
    mov di, ax
.scan_lead:                ; skip all leading spaces
    mov al, [si]
    or al, al
    jz .cut_trail
    cmp al, ' '
    jne .shift_left
    inc si
    jmp .scan_lead
.shift_left:               ; move string to the left
    mov al, [si]
    or al, al
    jz .done_shift
    movsb
    jmp .shift_left
.done_shift:
    mov byte [di], 0       ; restore terminator
    mov si, ax
    mov di, ax
.scan_trail:               ; scan for first space after non-space character
    mov al, [si]
    or al, al
    jz .cut_trail
    cmp al, ' '
    je .is_space
    mov di, si
    inc di
.is_space:
    inc si
    jmp .scan_trail
.cut_trail:
    mov byte [di], 0       ; place terminator after last non-space
.done:
    popa
    ret

; os_string_tokenize -- Reads tokens separated by specified char from a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none
os_string_tokenize:
    push ax
    push bx
    push si
    mov di, 0
.next:
    mov bl, [si]
    or bl, bl
    jz .done
    inc si
    cmp bl, al
    jne .next
.found:
    mov di, si
.done:
    pop si
    pop bx
    pop ax
    ret
